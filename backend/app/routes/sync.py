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
import logging
import uuid
from datetime import UTC, datetime
from typing import Any

from fastapi import APIRouter, Depends, Query, WebSocket, WebSocketDisconnect, status
from sqlalchemy import Column, DateTime, select
from sqlalchemy import inspect as sa_inspect
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.sql.base import ReadOnlyColumnCollection
from sqlmodel import SQLModel, col

from app.auth import AuthContext, require_device
from app.db import AsyncSessionLocal, get_session
from app.models import ChangeLog, Device, Game, GamePlayer, GameType, Player, Round, Score
from app.schemas.sync import (
    DeltaIn,
    DeltaOut,
    DeltaResult,
    PullResponse,
    PushRequest,
    PushResponse,
    WsTicketResponse,
)
from app.services.delta_bounds import check_payload as check_payload_bounds
from app.services.notify import listen_for_group, notify_new_seq
from app.services.ws_ticket import TICKET_TTL_SECONDS as WS_TICKET_TTL_SECONDS
from app.services.ws_ticket import consume as consume_ws_ticket
from app.services.ws_ticket import issue as issue_ws_ticket

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/sync", tags=["sync"])

# Map entity_type → SQLModel class. Limiting writes to known types is part of the
# auth boundary: a malicious client cannot trick us into writing to arbitrary tables.
_ENTITY_MAP: dict[str, type[SQLModel]] = {
    "player": Player,
    "game_type": GameType,
    "game": Game,
    "round": Round,
    "score": Score,
    "game_player": GamePlayer,
}


def _columns(cls: type[SQLModel]) -> ReadOnlyColumnCollection[str, Column[Any]]:
    """The mapped columns of a table class.

    ``cls.__table__`` works at runtime but is not declared on the SQLModel base, so it
    does not type-check. Inspecting the mapper is the supported route to the same thing.
    """
    mapper = sa_inspect(cls)
    assert mapper is not None  # every _ENTITY_MAP value is a mapped table class
    return mapper.columns


def _coerce_payload(cls: type[SQLModel], payload: dict) -> dict:
    """Convert JSON-string values into the Python types expected by SQLAlchemy columns.

    Handles:
    - DateTime columns receiving ISO 8601 strings → ``datetime``
    - UUID columns receiving hex/string → ``uuid.UUID``

    SQLAlchemy's SQLite dialect doesn't auto-parse these; Postgres usually does. We
    make the behavior uniform so the sync apply path works on both.
    """
    out: dict = {}
    columns = _columns(cls)
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
        select(col(ChangeLog.server_seq))
        .where(col(ChangeLog.group_id) == group_id)
        .order_by(col(ChangeLog.server_seq).desc())
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

    # Bound the values before anything reaches a column. Placed ahead of the game_player
    # branch so both apply paths are covered by one check.
    reason = check_payload_bounds(delta.entity_type, delta.payload)
    if reason is not None:
        return DeltaResult(delta_idx=-1, status="rejected", reason=reason)

    # GamePlayer has a composite PK and no uuid; we handle it specially.
    if delta.entity_type == "game_player":
        return await _apply_game_player(session, auth, delta, server_seq)

    payload = dict(delta.payload)
    # Force the server-side group_id (clients cannot move entities across groups).
    has_group_col = "group_id" in _columns(cls)
    if has_group_col:
        payload["group_id"] = auth.group.id
    else:
        payload.pop("group_id", None)

    # Look up by entity_uuid (the logical key for sync).
    existing = await session.execute(select(cls).where(_columns(cls)["id"] == delta.entity_uuid))
    obj = existing.scalar_one_or_none()

    now = datetime.now(UTC)
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
            # The driver message names tables, columns and constraints — useful in the
            # log, not something to hand back to a client.
            logger.warning("delta rejected on integrity error: %s", e.orig)
            return DeltaResult(
                delta_idx=-1, status="rejected", reason="integrity constraint violation"
            )
        return DeltaResult(delta_idx=-1, status="applied", server_seq=server_seq)

    # Update with LWW-per-field — we don't track per-field lamport yet in v1, so
    # we use a simpler row-level LWW: the highest (client_lamport, origin_device_id)
    # wins on the whole entity. Per-field LWW is a future enhancement (it would
    # require a field_versions table or denormalized columns).
    last_log = await session.execute(
        select(col(ChangeLog.client_lamport), col(ChangeLog.origin_device_id))
        .where(col(ChangeLog.entity_uuid) == delta.entity_uuid)
        .where(col(ChangeLog.op) == "upsert")
        .order_by(col(ChangeLog.client_lamport).desc(), col(ChangeLog.origin_device_id).desc())
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
    try:
        game_uuid, player_uuid = uuid.UUID(str(game_id)), uuid.UUID(str(player_id))
    except ValueError:
        return DeltaResult(delta_idx=-1, status="rejected", reason="malformed game_id/player_id")
    # Verify both belong to this group
    game = await session.get(Game, game_uuid)
    player = await session.get(Player, player_uuid)
    if game is None or game.group_id != auth.group.id:
        return DeltaResult(delta_idx=-1, status="rejected", reason="game not in group")
    if player is None or player.group_id != auth.group.id:
        return DeltaResult(delta_idx=-1, status="rejected", reason="player not in group")
    existing = await session.execute(
        select(GamePlayer).where(
            col(GamePlayer.game_id) == game.id, col(GamePlayer.player_id) == player.id
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
            select(col(ChangeLog.server_seq)).where(
                col(ChangeLog.origin_device_id) == auth.device.id,
                col(ChangeLog.client_lamport) == delta.client_lamport,
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
        .where(col(ChangeLog.group_id) == auth.group.id)
        .where(col(ChangeLog.server_seq) > since_seq)
        .order_by(col(ChangeLog.server_seq).asc())
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


async def _is_revoked(device_id: uuid.UUID) -> bool:
    """A stream outlives a single request, so revocation has to be re-checked on it."""
    async with AsyncSessionLocal() as session:
        device = await session.get(Device, device_id)
        return device is None or device.revoked_at is not None


@router.post("/ws-ticket", response_model=WsTicketResponse)
async def create_ws_ticket(auth: AuthContext = Depends(require_device)) -> WsTicketResponse:
    """Exchange the device token for a single-use ticket for ``/sync/stream``.

    The token itself must never travel in the stream URL: query strings land in proxy
    access logs and browser history. This request carries it in the Authorization
    header, where it belongs, and hands back a credential that expires in a minute and
    dies on first use.
    """
    ticket = issue_ws_ticket(auth.device.id, auth.group.id)
    return WsTicketResponse(ticket=ticket, expires_in=WS_TICKET_TTL_SECONDS)


@router.websocket("/stream")
async def stream(websocket: WebSocket, ticket: str = Query(default="")) -> None:
    """WS handshake auth: query param ``?ticket=<value from POST /sync/ws-ticket>``.

    The ticket is redeemed *before* accepting the connection, so an unauthenticated
    peer gets a handshake rejection and never reaches any expensive work — the previous
    scheme accepted first and then ran an argon2 verify per device row, which let any
    caller burn CPU at will.
    """
    redeemed = consume_ws_ticket(ticket)
    if redeemed is None:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return
    device_id, group_id = redeemed

    async with listen_for_group(group_id) as queue:
        await websocket.accept()
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
                except TimeoutError:
                    # Heartbeat — keeps proxies (Caddy/Nginx) from closing idle conns,
                    # and is where we notice a device revoked since the handshake.
                    if await _is_revoked(device_id):
                        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
                        return
                    await websocket.send_json({"type": "ping"})
        except WebSocketDisconnect:
            pass
        finally:
            receiver_task.cancel()
            with contextlib.suppress(asyncio.CancelledError):
                await receiver_task
