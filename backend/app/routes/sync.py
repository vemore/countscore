"""Delta-log sync endpoints — see .llmwiki/Sync.md.

Apply order on push:
1. Lock: the group row is read FOR UPDATE, so pushes to one group are serialised and
   ``groups.last_server_seq`` hands out each sequence number exactly once.
2. Dedup: skip deltas whose (origin_device_id, client_lamport) is already in change_log.
3. Materialize, inside a savepoint per delta: check that the entity and every parent it
   names belong to the caller's group, then apply with row-level LWW — the highest
   (client_lamport, origin_device_id) wins the whole entity, and a losing delta is
   discarded with status=merged_lww. A delete always wins: a tombstoned entity ignores
   every later upsert.
4. Append-to-log: an accepted delta becomes a change_log row carrying the known columns
   of its payload, never the server-controlled ones.
5. Notify: pg_notify('group_<uuid>', {server_seq}) before commit so listening
   WebSockets are woken.

A rejected delta rolls back its own savepoint and nothing else. Its reason is one of the
stable codes below, so a client can act on it without parsing prose.
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
from app.models import (
    ChangeLog,
    Device,
    Game,
    GameAnalysis,
    GamePlayer,
    GameType,
    Group,
    Player,
    Round,
    Score,
)
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

# Reject reasons a client is expected to branch on. Bounds failures keep their
# human-readable text (app/services/delta_bounds.py); these are the conflict codes.
REASON_NOT_IN_GROUP = "not in group"
REASON_PARENT_MISSING = "parent_missing"
REASON_ROUND_NUMBER_TAKEN = "round_number_taken"
REASON_SCORE_EXISTS = "score_exists"
REASON_NAME_TAKEN = "name_taken"
REASON_ANALYSIS_EXISTS = "analysis_exists"
REASON_INTEGRITY = "integrity constraint violation"

# Map entity_type → SQLModel class. Limiting writes to known types is part of the
# auth boundary: a malicious client cannot trick us into writing to arbitrary tables.
_ENTITY_MAP: dict[str, type[SQLModel]] = {
    "player": Player,
    "game_type": GameType,
    "game": Game,
    "round": Round,
    "score": Score,
    "game_player": GamePlayer,
    "game_analysis": GameAnalysis,
}

# Columns the server owns. They are never taken from a payload and never logged.
_SERVER_COLUMNS = frozenset({"id", "group_id", "created_at", "updated_at", "deleted_at"})


def _columns(cls: type[SQLModel]) -> ReadOnlyColumnCollection[str, Column[Any]]:
    """The mapped columns of a table class.

    ``cls.__table__`` works at runtime but is not declared on the SQLModel base, so it
    does not type-check. Inspecting the mapper is the supported route to the same thing.
    """
    mapper = sa_inspect(cls)
    assert mapper is not None  # every _ENTITY_MAP value is a mapped table class
    return mapper.columns


def _client_payload(cls: type[SQLModel], payload: dict) -> dict:
    """The part of a payload a client may set: known columns, minus the server's own."""
    columns = _columns(cls)
    return {k: v for k, v in payload.items() if k in columns and k not in _SERVER_COLUMNS}


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


def _as_uuid(value: Any) -> uuid.UUID | None:
    if isinstance(value, uuid.UUID):
        return value
    try:
        return uuid.UUID(str(value))
    except ValueError:
        return None


async def _game_in_group(session: AsyncSession, game_id: Any, group_id: uuid.UUID) -> bool:
    gid = _as_uuid(game_id)
    if gid is None:
        return False
    game = await session.get(Game, gid)
    return game is not None and game.group_id == group_id


async def _round_in_group(session: AsyncSession, round_id: Any, group_id: uuid.UUID) -> bool:
    rid = _as_uuid(round_id)
    if rid is None:
        return False
    rnd = await session.get(Round, rid)
    return rnd is not None and await _game_in_group(session, rnd.game_id, group_id)


async def _owned_by(
    session: AsyncSession, cls: type[SQLModel], obj: Any, group_id: uuid.UUID
) -> bool:
    """Whether an existing row belongs to ``group_id``, directly or through its parents."""
    if cls in (Player, GameType, Game):
        return bool(obj.group_id == group_id)
    if cls in (Round, GameAnalysis):
        return await _game_in_group(session, obj.game_id, group_id)
    if cls is Score:
        return await _round_in_group(session, obj.round_id, group_id)
    return False


async def _check_parents(
    session: AsyncSession, cls: type[SQLModel], values: dict, group_id: uuid.UUID
) -> str | None:
    """Every parent a payload names must exist in the caller's group.

    A parent in another group answers exactly like a missing one: the caller learns
    nothing about other groups' ids.
    """
    checks: list[tuple[str, type[SQLModel]]] = []
    if cls is Game and values.get("game_type_id") is not None:
        checks.append(("game_type_id", GameType))
    if cls in (Round, GameAnalysis) and "game_id" in values:
        checks.append(("game_id", Game))
    if cls is Score:
        if "round_id" in values:
            checks.append(("round_id", Round))
        if "player_id" in values:
            checks.append(("player_id", Player))
    for key, parent_cls in checks:
        parent_id = _as_uuid(values[key])
        if parent_id is None:
            return REASON_PARENT_MISSING
        parent = await session.get(parent_cls, parent_id)
        if parent is None or not await _owned_by(session, parent_cls, parent, group_id):
            return REASON_PARENT_MISSING
    return None


async def _check_unique(
    session: AsyncSession, cls: type[SQLModel], entity_uuid: uuid.UUID, row: dict
) -> str | None:
    """Name the live-row uniqueness rule a write would break, before the flush does.

    ``row`` holds the values the row will have after the write. The unique indexes stay
    the backstop; this only turns their violation into a reason a client can act on.
    """
    rules: dict[type[SQLModel], tuple[tuple[str, ...], str]] = {
        Round: (("game_id", "round_number"), REASON_ROUND_NUMBER_TAKEN),
        Score: (("player_id", "round_id"), REASON_SCORE_EXISTS),
        GameAnalysis: (("game_id",), REASON_ANALYSIS_EXISTS),
        Player: (("group_id", "name_normalized"), REASON_NAME_TAKEN),
        GameType: (("group_id", "name"), REASON_NAME_TAKEN),
    }
    rule = rules.get(cls)
    if rule is None:
        return None
    keys, reason = rule
    if any(row.get(k) is None for k in keys):
        return None
    columns = _columns(cls)
    query = select(columns["id"]).where(
        columns["id"] != entity_uuid, columns["deleted_at"].is_(None)
    )
    for k in keys:
        query = query.where(columns[k] == row[k])
    clash = await session.execute(query.limit(1))
    return reason if clash.first() is not None else None


async def _was_deleted(session: AsyncSession, group_id: uuid.UUID, entity_uuid: uuid.UUID) -> bool:
    """Whether the group's log holds a delete for this entity. A delete always wins."""
    result = await session.execute(
        select(col(ChangeLog.id))
        .where(col(ChangeLog.group_id) == group_id)
        .where(col(ChangeLog.entity_uuid) == entity_uuid)
        .where(col(ChangeLog.op) == "delete")
        .limit(1)
    )
    return result.first() is not None


def _rejected(reason: str) -> DeltaResult:
    return DeltaResult(delta_idx=-1, status="rejected", reason=reason)


async def _apply_delta(
    session: AsyncSession, auth: AuthContext, delta: DeltaIn, server_seq: int
) -> DeltaResult:
    cls = _ENTITY_MAP.get(delta.entity_type)
    if cls is None:
        return _rejected("unknown entity type")

    # Bound the values before anything reaches a column. Placed ahead of the game_player
    # branch so both apply paths are covered by one check.
    reason = check_payload_bounds(delta.entity_type, delta.payload)
    if reason is not None:
        return _rejected(reason)

    # GamePlayer has a composite PK and no uuid; we handle it specially.
    if delta.entity_type == "game_player":
        return await _apply_game_player(session, auth, delta, server_seq)

    group_id = auth.group.id
    has_group_col = "group_id" in _columns(cls)
    applied = DeltaResult(delta_idx=-1, status="applied", server_seq=server_seq)

    # Look up by entity_uuid (the logical key for sync), then check the row is ours. A
    # row of another group is refused, never adopted: clients cannot move entities
    # across groups, and a revoked device cannot reach its former group's data.
    obj = await session.get(cls, delta.entity_uuid)
    if obj is not None and not await _owned_by(session, cls, obj, group_id):
        return _rejected(REASON_NOT_IN_GROUP)

    now = datetime.now(UTC)
    if delta.op == "delete":
        if obj is not None and obj.deleted_at is None:  # type: ignore[attr-defined]
            obj.deleted_at = now
            obj.updated_at = now
        # A delete for an unknown uuid is still logged: it stops a later upsert of that
        # uuid from resurrecting it (see _was_deleted).
        return applied

    # Delete wins, whichever lamport the upsert carries.
    if (obj is not None and obj.deleted_at is not None) or await _was_deleted(  # type: ignore[attr-defined]
        session, group_id, delta.entity_uuid
    ):
        return DeltaResult(delta_idx=-1, status="merged_lww", server_seq=server_seq)

    values = _coerce_payload(cls, _client_payload(cls, delta.payload))
    reason = await _check_parents(session, cls, values, group_id)
    if reason is not None:
        return _rejected(reason)

    if obj is None:
        row = {**values, "id": delta.entity_uuid}
        if has_group_col:
            row["group_id"] = group_id
        reason = await _check_unique(session, cls, delta.entity_uuid, row)
        if reason is not None:
            return _rejected(reason)
        row["created_at"] = row["updated_at"] = now
        session.add(cls(**row))
        await session.flush()
        return applied

    # Row-level LWW: the highest (client_lamport, origin_device_id) wins the whole
    # entity. Per-field LWW would need a field_versions table; see .llmwiki/Sync.md.
    last_log = await session.execute(
        select(col(ChangeLog.client_lamport), col(ChangeLog.origin_device_id))
        .where(col(ChangeLog.group_id) == group_id)
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

    current = {c.key: getattr(obj, c.key) for c in _columns(cls) if c.key}
    reason = await _check_unique(session, cls, delta.entity_uuid, {**current, **values})
    if reason is not None:
        return _rejected(reason)
    for key, value in values.items():
        setattr(obj, key, value)
    obj.updated_at = now
    await session.flush()
    return applied


async def _apply_game_player(
    session: AsyncSession, auth: AuthContext, delta: DeltaIn, server_seq: int
) -> DeltaResult:
    # GamePlayer has composite PK (game_id, player_id), encoded in payload.
    game_id = delta.payload.get("game_id")
    player_id = delta.payload.get("player_id")
    if not game_id or not player_id:
        return _rejected("missing game_id/player_id")
    try:
        game_uuid, player_uuid = uuid.UUID(str(game_id)), uuid.UUID(str(player_id))
    except ValueError:
        return _rejected("malformed game_id/player_id")
    # Verify both belong to this group
    game = await session.get(Game, game_uuid)
    player = await session.get(Player, player_uuid)
    if game is None or game.group_id != auth.group.id:
        return _rejected("game not in group")
    if player is None or player.group_id != auth.group.id:
        return _rejected("player not in group")
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
    await session.flush()
    return DeltaResult(delta_idx=-1, status="applied", server_seq=server_seq)


def _logged_payload(delta: DeltaIn) -> dict[str, Any]:
    """What other devices pull: the payload's known client columns, JSON as sent."""
    cls = _ENTITY_MAP[delta.entity_type]
    if delta.entity_type == "game_player":
        return {k: v for k, v in delta.payload.items() if k in _columns(cls)}
    return _client_payload(cls, delta.payload)


@router.post("/push", response_model=PushResponse)
async def push(
    body: PushRequest,
    auth: AuthContext = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> PushResponse:
    results: list[DeltaResult] = []
    max_seq = 0

    # Serialises pushes to this group, which is what makes last_server_seq safe to bump.
    # populate_existing: require_device already loaded this row into the session, and
    # the value that counts is the one read under the lock, not that earlier copy.
    group = await session.get(Group, auth.group.id, with_for_update=True, populate_existing=True)
    assert group is not None  # require_device just loaded it
    next_seq = group.last_server_seq + 1

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
            results.append(DeltaResult(delta_idx=idx, status="duplicate", server_seq=dup_seq))
            max_seq = max(max_seq, dup_seq)
            continue

        savepoint = await session.begin_nested()
        try:
            outcome = await _apply_delta(session, auth, delta, next_seq)
            if outcome.status in ("applied", "merged_lww"):
                session.add(
                    ChangeLog(
                        group_id=group.id,
                        origin_device_id=auth.device.id,
                        entity_type=delta.entity_type,
                        entity_uuid=delta.entity_uuid,
                        op=delta.op,
                        payload=_logged_payload(delta),
                        client_lamport=delta.client_lamport,
                        server_seq=next_seq,
                    )
                )
            await savepoint.commit()
        except IntegrityError as e:
            # Only this delta's savepoint is undone: every earlier delta of the batch
            # keeps its row and its log entry. The driver message names tables and
            # constraints — useful in the log, not something to hand back to a client.
            await savepoint.rollback()
            logger.warning("delta rejected on integrity error: %s", e.orig)
            outcome = _rejected(REASON_INTEGRITY)

        outcome.delta_idx = idx
        if outcome.status in ("applied", "merged_lww"):
            max_seq = next_seq
            next_seq += 1
        results.append(outcome)

    group.last_server_seq = next_seq - 1
    if max_seq > 0:
        await notify_new_seq(session, group.id, max_seq)
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
