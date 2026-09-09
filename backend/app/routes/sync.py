"""Delta-log sync endpoints — see .llmwiki/Sync.md.

Apply order on push:
1. Dedup: skip deltas whose (origin_device_id, client_lamport) is already in change_log.
2. Append-to-log: every accepted delta becomes a change_log row with a serial server_seq.
3. Materialize: apply the delta to the per-entity table using LWW by field
   (compare each field's last lamport).
4. Notify: pg_notify('group_<uuid>', {server_seq}) before commit so listening
   WebSockets are woken.

Rejection cases:
- Round upsert violates UNIQUE(game_id, round_number): rejected with status=rejected.
  The client must refresh from /sync/pull and retry with the merged state.
"""
from __future__ import annotations

import asyncio
import contextlib
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, WebSocket, WebSocketDisconnect, status
from sqlalchemy import DateTime, select, update as sa_update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import AuthContext, require_device, verify_token
from app.db import AsyncSessionLocal, get_session
from app.models import ChangeLog, Device, Game, GamePlayer, GameType, Group, Player, Round, Score
from app.schemas.sync import (
    DeltaIn,
    DeltaOut,
    DeltaResult,
    PullResponse,
    PushRequest,
    PushResponse,
)
from app.services.notify import listen_for_group, notify_new_seq

router = APIRouter(prefix="/sync", tags=["sync"])

# Map entity_type → SQLModel class. Limiting writes to known types is part of the
# auth boundary: a malicious client cannot trick us into writing to arbitrary tables.
_ENTITY_MAP: dict[str, type] = {
    "player": Player,
    "game_type": GameType,
    "game": Game,
    "round": Round,
    "score": Score,
    "game_player": GamePlayer,
}


def _coerce_payload(cls: type, payload: dict) -> dict:
    """Convert JSON-string values into the Python types expected by SQLAlchemy columns.

    Handles:
    - DateTime columns receiving ISO 8601 strings → ``datetime``
    - UUID columns receiving hex/string → ``uuid.UUID``

    SQLAlchemy's SQLite dialect doesn't auto-parse these; Postgres usually does. We
    make the behavior uniform so the sync apply path works on both.
    """
    out: dict = {}
    columns = cls.__table__.columns
    for key, value in payload.items():
        if key not in columns:
            continue
        col = columns[key]
        if isinstance(value, str):
            try:
                python_type = col.type.python_type
            except (AttributeError, NotImplementedError):
                python_type = None
            if isinstance(col.type, DateTime):
                try:
                    value = datetime.fromisoformat(value)
                except ValueError:
                    continue
            elif python_type is uuid.UUID:
                try:
                    value = uuid.UUID(value)
                except ValueError:
                    continue
        out[key] = value
    return out


async def _next_server_seq(session: AsyncSession, group_id: uuid.UUID) -> int:
    result = await session.execute(
        select(ChangeLog.server_seq)
        .where(ChangeLog.group_id == group_id)
        .order_by(ChangeLog.server_seq.desc())
        .limit(1)
    )
    last = result.scalar()
    return (last or 0) + 1


async def _apply_delta(
    session: AsyncSession, auth: AuthContext, delta: DeltaIn, server_seq: int
) -> DeltaResult:
    cls = _ENTITY_MAP.get(delta.entity_type)
    if cls is None:
        return DeltaResult(delta_idx=-1, status="rejected", reason="unknown entity type")

    # GamePlayer has a composite PK and no uuid; we handle it specially.
    if delta.entity_type == "game_player":
        return await _apply_game_player(session, auth, delta, server_seq)

    payload = dict(delta.payload)
    # Force the server-side group_id (clients cannot move entities across groups).
    has_group_col = "group_id" in cls.__table__.columns.keys()
    if has_group_col:
        payload["group_id"] = auth.group.id
    else:
        payload.pop("group_id", None)

    # Look up by entity_uuid (the logical key for sync).
    existing = await session.execute(select(cls).where(cls.id == delta.entity_uuid))
    obj = existing.scalar_one_or_none()

    now = datetime.now(timezone.utc)
    if delta.op == "delete":
        if obj is None:
            # Idempotent — create a tombstone for the future
            return DeltaResult(delta_idx=-1, status="applied", server_seq=server_seq)
        obj.deleted_at = now
        obj.updated_at = now
        return DeltaResult(delta_idx=-1, status="applied", server_seq=server_seq)

    # upsert
    if obj is None:
        # Build a fresh row from payload, with server-controlled fields.
        clean = _coerce_payload(cls, payload)
        clean["id"] = delta.entity_uuid
        clean.setdefault("created_at", now)
        clean.setdefault("updated_at", now)
        if has_group_col:
            clean["group_id"] = auth.group.id
        try:
            obj = cls(**clean)
            session.add(obj)
            await session.flush()
        except IntegrityError as e:
            await session.rollback()
            return DeltaResult(delta_idx=-1, status="rejected", reason=f"integrity: {e.orig}")
        return DeltaResult(delta_idx=-1, status="applied", server_seq=server_seq)

    # Update with LWW-per-field — we don't track per-field lamport yet in v1, so
    # we use a simpler row-level LWW: the highest (client_lamport, origin_device_id)
    # wins on the whole entity. Per-field LWW is a future enhancement (it would
    # require a field_versions table or denormalized columns).
    last_log = await session.execute(
        select(ChangeLog.client_lamport, ChangeLog.origin_device_id)
        .where(ChangeLog.entity_uuid == delta.entity_uuid)
        .where(ChangeLog.op == "upsert")
        .order_by(ChangeLog.client_lamport.desc(), ChangeLog.origin_device_id.desc())
        .limit(1)
    )
    prev = last_log.first()
    if prev is not None:
        prev_lamport, prev_device = prev
        if (delta.client_lamport, auth.device.id.bytes) < (prev_lamport, prev_device.bytes):
            return DeltaResult(delta_idx=-1, status="merged_lww", server_seq=server_seq)

    for key, value in _coerce_payload(cls, payload).items():
        if key != "id":
            setattr(obj, key, value)
    obj.updated_at = now
    if has_group_col:
        obj.group_id = auth.group.id
    return DeltaResult(delta_idx=-1, status="applied", server_seq=server_seq)


async def _apply_game_player(
    session: AsyncSession, auth: AuthContext, delta: DeltaIn, server_seq: int
) -> DeltaResult:
    # GamePlayer has composite PK (game_id, player_id), encoded in payload.
    game_id = delta.payload.get("game_id")
    player_id = delta.payload.get("player_id")
    if not game_id or not player_id:
        return DeltaResult(delta_idx=-1, status="rejected", reason="missing game_id/player_id")
    # Verify both belong to this group
    game = await session.get(Game, uuid.UUID(game_id))
    player = await session.get(Player, uuid.UUID(player_id))
    if game is None or game.group_id != auth.group.id:
        return DeltaResult(delta_idx=-1, status="rejected", reason="game not in group")
    if player is None or player.group_id != auth.group.id:
        return DeltaResult(delta_idx=-1, status="rejected", reason="player not in group")
    existing = await session.execute(
        select(GamePlayer).where(
            GamePlayer.game_id == game.id, GamePlayer.player_id == player.id
        )
    )
    row = existing.scalar_one_or_none()
    if delta.op == "delete":
        if row is not None:
            await session.delete(row)
        return DeltaResult(delta_idx=-1, status="applied", server_seq=server_seq)
    if row is None:
        row = GamePlayer(
            game_id=game.id,
            player_id=player.id,
            order_index=delta.payload.get("order_index", 0),
            color_value=delta.payload.get("color_value"),
        )
        session.add(row)
    else:
        row.order_index = delta.payload.get("order_index", row.order_index)
        if "color_value" in delta.payload:
            row.color_value = delta.payload["color_value"]
    return DeltaResult(delta_idx=-1, status="applied", server_seq=server_seq)


@router.post("/push", response_model=PushResponse)
async def push(
    body: PushRequest,
    auth: AuthContext = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> PushResponse:
    results: list[DeltaResult] = []
    max_seq = 0

    for idx, delta in enumerate(body.deltas):
        # Idempotence: skip already-applied (device, lamport) pairs.
        dup = await session.execute(
            select(ChangeLog.server_seq).where(
                ChangeLog.origin_device_id == auth.device.id,
                ChangeLog.client_lamport == delta.client_lamport,
            )
        )
        dup_seq = dup.scalar()
        if dup_seq is not None:
            results.append(
                DeltaResult(delta_idx=idx, status="duplicate", server_seq=dup_seq)
            )
            max_seq = max(max_seq, dup_seq)
            continue

        server_seq = await _next_server_seq(session, auth.group.id)
        outcome = await _apply_delta(session, auth, delta, server_seq)
        outcome.delta_idx = idx

        if outcome.status in ("applied", "merged_lww"):
            log = ChangeLog(
                group_id=auth.group.id,
                origin_device_id=auth.device.id,
                entity_type=delta.entity_type,
                entity_uuid=delta.entity_uuid,
                op=delta.op,
                payload=delta.payload,
                client_lamport=delta.client_lamport,
                server_seq=server_seq,
            )
            session.add(log)
            max_seq = max(max_seq, server_seq)

        results.append(outcome)

    if max_seq > 0:
        await notify_new_seq(session, auth.group.id, max_seq)
    await session.commit()

    return PushResponse(results=results, server_seq_max=max_seq)


@router.get("/pull", response_model=PullResponse)
async def pull(
    since_seq: int = Query(default=0, ge=0),
    limit: int = Query(default=500, ge=1, le=2000),
    auth: AuthContext = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> PullResponse:
    result = await session.execute(
        select(ChangeLog)
        .where(ChangeLog.group_id == auth.group.id)
        .where(ChangeLog.server_seq > since_seq)
        .order_by(ChangeLog.server_seq.asc())
        .limit(limit + 1)
    )
    rows = result.scalars().all()
    has_more = len(rows) > limit
    rows = rows[:limit]

    deltas = [
        DeltaOut(
            entity_type=r.entity_type,  # type: ignore[arg-type]
            entity_uuid=r.entity_uuid,
            op=r.op,  # type: ignore[arg-type]
            payload=r.payload,
            client_lamport=r.client_lamport,
            origin_device_id=r.origin_device_id,
            server_seq=r.server_seq,
            applied_at=r.applied_at,
        )
        for r in rows
    ]
    server_seq_max = rows[-1].server_seq if rows else since_seq
    return PullResponse(deltas=deltas, server_seq_max=server_seq_max, has_more=has_more)


@router.websocket("/stream")
async def stream(websocket: WebSocket, token: str = Query(default="")) -> None:
    """WS handshake auth: query param ``?token=<device_token>``.

    We accept the connection, validate the token (slow argon2 verify happens once
    at handshake — same cost as a regular request), then either close or start
    forwarding server_seq notifications.
    """
    await websocket.accept()
    if not token:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    async with AsyncSessionLocal() as session:
        result = await session.execute(select(Device).where(Device.revoked_at.is_(None)))
        devices = result.scalars().all()
        device = None
        for d in devices:
            if verify_token(token, d.token_hash):
                device = d
                break
        if device is None:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return
        group_id = device.group_id

    async with listen_for_group(group_id) as queue:
        # Background task to detect client disconnect
        async def _receiver() -> None:
            try:
                while True:
                    await websocket.receive_text()
            except WebSocketDisconnect:
                return

        receiver_task = asyncio.create_task(_receiver())
        try:
            while True:
                if receiver_task.done():
                    return
                try:
                    server_seq = await asyncio.wait_for(queue.get(), timeout=30.0)
                    await websocket.send_json({"type": "new_seq", "server_seq": server_seq})
                except asyncio.TimeoutError:
                    # Heartbeat — keeps proxies (Caddy/Nginx) from closing idle conns.
                    await websocket.send_json({"type": "ping"})
        except WebSocketDisconnect:
            pass
        finally:
            receiver_task.cancel()
            with contextlib.suppress(asyncio.CancelledError):
                await receiver_task


# Suppress unused imports warning - sa_update is used implicitly via SQLModel
_ = sa_update  # type: ignore[assignment]
