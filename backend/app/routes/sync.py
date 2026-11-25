"""Delta-log sync endpoints — see .llmwiki/Sync.md.

Apply order on push:
1. Lock: the group row is read FOR UPDATE, so pushes to one group are serialised and
   ``groups.last_server_seq`` hands out each sequence number exactly once.
2. Dedup: a delta whose (origin_device_id, client_lamport) is already in change_log is a
   ``duplicate`` when it is the logged delta again (a network retry), and is rejected
   ``lamport_reused`` when it carries something else under that lamport (a device
   restored from a backup re-stamping lamports it had already used).
3. Materialize, inside a savepoint per delta: check every value's JSON type against its
   column, that the entity and every parent it names belong to the caller's group, then
   apply with row-level LWW — the highest
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
import re
import unicodedata
import uuid
from datetime import UTC, datetime
from typing import Any

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Query,
    WebSocket,
    WebSocketDisconnect,
    status,
)
from sqlalchemy import (
    BigInteger,
    Boolean,
    Column,
    DateTime,
    Integer,
    String,
    TypeDecorator,
    Uuid,
    select,
)
from sqlalchemy import inspect as sa_inspect
from sqlalchemy.exc import DataError, DBAPIError, IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.sql.base import ReadOnlyColumnCollection
from sqlmodel import SQLModel, col

from app.auth import AuthContext, require_device
from app.config import get_settings
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
    BIGINT_MAX,
    DeltaIn,
    DeltaOut,
    DeltaResult,
    PullResponse,
    PushRequest,
    PushResponse,
    WsTicketResponse,
)
from app.services.delta_bounds import check_payload as check_payload_bounds
from app.services.ip_rate_limiter import check_ip_rate_limit
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
REASON_BUILTIN_KEY_TAKEN = "builtin_key_taken"
REASON_ANALYSIS_EXISTS = "analysis_exists"
# The device already used this client_lamport for another delta. A true retry carries
# the logged delta again and is a ``duplicate``; anything else under a used lamport is a
# device whose clock went back — restored from a backup — and must re-stamp past it.
REASON_LAMPORT_REUSED = "lamport_reused"
REASON_UNKNOWN_ENTITY = "unknown entity type"
REASON_INTEGRITY = "integrity constraint violation"
# A value the database refused that no check above caught. A backstop, like
# REASON_INTEGRITY: it keeps one delta from turning the whole push into a 500.
REASON_INVALID_VALUE = "invalid value"

_INT32 = (-(2**31), 2**31 - 1)
_INT64 = (-BIGINT_MAX - 1, BIGINT_MAX)
# What DateTime columns accept: ISO 8601 as Dart's ``toIso8601String`` writes it, the only
# shape every client can parse back. Python's ``fromisoformat`` also takes week dates and
# other forms the app's ``DateTime.parse`` throws on — on every device that pulls them.
# The zone is required: without one, each pulling device reads its own local time. The
# app sends UTC with a ``Z`` (``_isoUtc``, lib/services/sync/sync_store.dart).
_TIMESTAMP = re.compile(
    r"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,6})?(?:Z|[+-][0-9]{2}:[0-9]{2})"
)

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


def _is_timestamp(value: str) -> bool:
    if _TIMESTAMP.fullmatch(value) is None:
        return False
    try:
        datetime.fromisoformat(value)
    except ValueError:  # matches the shape, names no real instant: month 13, hour 25
        return False
    return True


def _value_problem(cls: type[SQLModel], payload: dict) -> str | None:
    """Why a value cannot go into its column, or None when every value fits.

    A value of the wrong JSON type used to reach the driver: a string in a boolean column
    or a number in a timestamp one failed the whole push with a 500, and a client retries
    that same batch for ever. A malformed timestamp was dropped from the row but kept in
    the log, so every device that pulled it threw. Null is left to the NOT NULL backstop.
    """
    columns = _columns(cls)
    for key, value in _client_payload(cls, payload).items():
        if value is None:
            continue
        column_type = columns[key].type
        if isinstance(column_type, TypeDecorator):  # SQLModel's AutoString wraps a String
            column_type = column_type.impl_instance
        if isinstance(column_type, Boolean):
            if not isinstance(value, bool):
                return f"{key} must be a boolean"
        elif isinstance(column_type, Integer):  # BigInteger included
            if not isinstance(value, int) or isinstance(value, bool):
                return f"{key} must be an integer"
            low, high = _INT64 if isinstance(column_type, BigInteger) else _INT32
            if not low <= value <= high:
                return f"{key} out of bounds ({low}..{high})"
        elif isinstance(column_type, DateTime):
            if not isinstance(value, str) or not _is_timestamp(value):
                return f"{key} must be an ISO 8601 timestamp"
        elif isinstance(column_type, Uuid):
            # Every uuid a client sets names a parent; a malformed one names none.
            if not isinstance(value, str) or _as_uuid(value) is None:
                return REASON_PARENT_MISSING
        elif isinstance(column_type, String):  # Text and AutoString included
            if not isinstance(value, str):
                return f"{key} must be a string"
            # Postgres refuses both in a text column and in the jsonb log.
            if "\x00" in value:
                return f"{key} contains a NUL character"
            try:
                value.encode("utf-8")
            except UnicodeEncodeError:  # a lone surrogate, "\ud800"
                return f"{key} is not valid UTF-8"
    return None


def _name_fold(value: str) -> str:
    """What every lowercasing of a name has in common, to tell a variant from another name.

    The app's ``normalizeName`` (``lib/services/sync/sync_ids.dart``) is Dart's
    ``trim().toLowerCase()``, and it differs by platform and from Python's ``lower``:
    Python and JavaScript (the PWA) apply the final-sigma rule and turn "İ" into "i"
    plus a combining dot above, while the Dart VM maps code by code ("ΣΟΦΟΣ" → "σοφοσ",
    "İ" → "i"). Casefolding merges the sigmas; dropping a dot above left free after NFC
    merges the two "i". A dot above that composes with its letter ("ż") is kept.
    """
    return unicodedata.normalize("NFC", value.casefold()).replace("̇", "")


def _derived_name_normalized(name: str) -> str:
    """``normalizeName`` as the Dart VM computes it, for a payload that sent none.

    Code by code, so no final sigma, and "İ" to a single "i", so the value never outgrows
    the name. Trimmed of spaces only: the player-name allow-list admits no other
    whitespace, so Dart's and Python's different trim sets never meet a stored name.
    """
    return "".join("i" if c == "İ" else c.lower() for c in name.strip(" "))


def _canonical(delta: DeltaIn) -> DeltaIn:
    """The delta as the server applies, logs and compares it.

    A player's ``name_normalized`` is what ``name_taken`` compares. The client's value is
    kept when it is a lowercasing of ``name`` — each platform's own, see ``_name_fold`` —
    so two names a device holds apart stay apart here ("ΣΟΦΟΣ" and "Σοφος" are two
    players to the app). It is derived from ``name`` when absent or contradicting: a
    rename that left the stale one behind, or one naming someone else, let two live
    players share a name.
    """
    if delta.entity_type != "player":
        return delta
    payload = dict(delta.payload)
    name = payload.get("name")
    if isinstance(name, str):
        sent = payload.get("name_normalized")
        # Compared with the trimmed name, so a value that kept the name's spaces is not one.
        if not isinstance(sent, str) or _name_fold(sent) != _name_fold(name.strip(" ")):
            payload["name_normalized"] = _derived_name_normalized(name)
    else:
        payload.pop("name_normalized", None)
    return delta.model_copy(update={"payload": payload})


def _is_logged_delta(logged: ChangeLog, delta: DeltaIn) -> bool:
    """Whether ``delta`` is the very delta ``logged`` recorded — a network retry.

    The logged payload goes through today's ``_canonical`` again, and only the keys it
    holds are compared: a retry that spans a deploy — one that canonicalises otherwise,
    or logs a column the older server did not know — is still the same delta.
    """
    if (logged.entity_type, logged.entity_uuid, logged.op) != (
        delta.entity_type,
        delta.entity_uuid,
        delta.op,
    ):
        return False
    then = _logged_payload(
        _canonical(
            DeltaIn.model_construct(
                entity_type=logged.entity_type,
                entity_uuid=logged.entity_uuid,
                op=logged.op,
                payload=dict(logged.payload),
                client_lamport=logged.client_lamport,
            )
        )
    )
    now = _logged_payload(delta)
    if then is None or now is None:
        return False
    return all(key in now and now[key] == value for key, value in then.items())


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
    rules: dict[type[SQLModel], tuple[tuple[tuple[str, ...], str], ...]] = {
        Round: ((("game_id", "round_number"), REASON_ROUND_NUMBER_TAKEN),),
        Score: ((("player_id", "round_id"), REASON_SCORE_EXISTS),),
        GameAnalysis: ((("game_id",), REASON_ANALYSIS_EXISTS),),
        Player: ((("group_id", "name_normalized"), REASON_NAME_TAKEN),),
        # A game type carries two: its name, and — for a built-in one — the key
        # that identifies it whatever the pushing device's locale calls it.
        GameType: (
            (("group_id", "name"), REASON_NAME_TAKEN),
            (("group_id", "builtin_key"), REASON_BUILTIN_KEY_TAKEN),
        ),
    }
    columns = _columns(cls)
    for keys, reason in rules.get(cls, ()):
        if any(row.get(k) is None for k in keys):
            continue
        query = select(columns["id"]).where(
            columns["id"] != entity_uuid, columns["deleted_at"].is_(None)
        )
        for k in keys:
            query = query.where(columns[k] == row[k])
        clash = await session.execute(query.limit(1))
        if clash.first() is not None:
            return reason
    return None


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
        return _rejected(REASON_UNKNOWN_ENTITY)

    # Bound the values before anything reaches a column. Placed ahead of the game_player
    # branch so both apply paths are covered by one check.
    reason = check_payload_bounds(delta.entity_type, delta.payload)
    if reason is not None:
        return _rejected(reason)

    # GamePlayer has a composite PK and no uuid; we handle it specially. Its two uuids
    # are checked there, and its two integers by the bounds above.
    if delta.entity_type == "game_player":
        return await _apply_game_player(session, auth, delta, server_seq)

    reason = _value_problem(cls, delta.payload)
    if reason is not None:
        return _rejected(reason)

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


def _logged_payload(delta: DeltaIn) -> dict[str, Any] | None:
    """What other devices pull: the payload's known client columns, JSON as sent.

    None for an entity type this server does not know, which it never logs.
    """
    cls = _ENTITY_MAP.get(delta.entity_type)
    if cls is None:
        return None
    if delta.entity_type == "game_player":
        return {k: v for k, v in delta.payload.items() if k in _columns(cls)}
    return _client_payload(cls, delta.payload)


def _refused_value(error: DBAPIError) -> bool:
    """Whether the database refused a value, rather than failed.

    asyncpg's errors reach SQLAlchemy as a generic ``DBAPIError`` carrying the SQLSTATE,
    never as ``DataError``: class 22 is "data exception" — a NUL byte (22021), a
    parameter the driver could not encode (22000), a number out of range (22003).
    """
    sqlstate = str(getattr(error.orig, "sqlstate", None) or "")
    return isinstance(error, DataError) or sqlstate.startswith("22")


def _enforce_push_rate_limit(device_id: uuid.UUID) -> None:
    """Per-device throttle on /sync/push.

    The in-memory limiter, keyed by device rather than address: the ``rate_limits`` table
    is the LLM quota, and one row per device leaves no room for a second scope.
    """
    settings = get_settings()
    dec = check_ip_rate_limit(
        str(device_id),
        bucket="sync_push",
        per_minute=settings.sync_push_rl_per_minute,
        per_hour=settings.sync_push_rl_per_hour,
    )
    if not dec.allowed:
        raise HTTPException(
            status.HTTP_429_TOO_MANY_REQUESTS,
            f"rate-limited at {dec.scope} scope",
            headers={"Retry-After": str(dec.retry_after_seconds)},
        )


@router.post("/push", response_model=PushResponse)
async def push(
    body: PushRequest,
    auth: AuthContext = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> PushResponse:
    _enforce_push_rate_limit(auth.device.id)
    results: list[DeltaResult] = []
    max_seq = 0

    # Serialises pushes to this group, which is what makes last_server_seq safe to bump.
    # populate_existing: require_device already loaded this row into the session, and
    # the value that counts is the one read under the lock, not that earlier copy.
    group = await session.get(Group, auth.group.id, with_for_update=True, populate_existing=True)
    assert group is not None  # require_device just loaded it
    next_seq = group.last_server_seq + 1

    for idx, raw_delta in enumerate(body.deltas):
        delta = _canonical(raw_delta)
        # Idempotence: a (device, lamport) pair already logged is answered from the log.
        dup = await session.execute(
            select(ChangeLog).where(
                col(ChangeLog.origin_device_id) == auth.device.id,
                col(ChangeLog.client_lamport) == delta.client_lamport,
            )
        )
        logged = dup.scalar_one_or_none()
        if logged is not None:
            if _is_logged_delta(logged, delta):
                results.append(
                    DeltaResult(delta_idx=idx, status="duplicate", server_seq=logged.server_seq)
                )
                max_seq = max(max_seq, logged.server_seq)
            else:
                # Not a retry: the device's clock went back. Answering `duplicate` here
                # told it a write it never made had been kept, and the edit was lost.
                outcome = _rejected(REASON_LAMPORT_REUSED)
                outcome.delta_idx = idx
                results.append(outcome)
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
                        payload=_logged_payload(delta) or {},
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
            # %r, not %s: the driver text quotes the payload, newlines included, and a
            # raw newline would forge a log line.
            logger.warning("delta rejected on integrity error: %r", e.orig)
            outcome = _rejected(REASON_INTEGRITY)
        except DBAPIError as e:
            # A value the database refused that _value_problem let through: same
            # isolation. Anything else — a lost connection, a timeout — is not the
            # delta's fault, and still fails the request.
            if not _refused_value(e):
                raise
            await savepoint.rollback()
            logger.warning("delta rejected on data error: %r", e.orig)
            outcome = _rejected(REASON_INVALID_VALUE)

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
    since_seq: int = Query(default=0, ge=0, le=BIGINT_MAX),
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


# Open /sync/stream connections per device. Process-local, like the WS tickets.
_open_streams: dict[uuid.UUID, int] = {}


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

    # Each stream costs a queue and a coroutine, no longer a Postgres connection, but one
    # device must still not hold hundreds. Refused before accept(), like a bad ticket.
    if _open_streams.get(device_id, 0) >= get_settings().max_streams_per_device:
        await websocket.close(code=status.WS_1013_TRY_AGAIN_LATER)
        return
    _open_streams[device_id] = _open_streams.get(device_id, 0) + 1
    try:
        await _serve_stream(websocket, device_id, group_id)
    finally:
        _open_streams[device_id] -= 1
        if not _open_streams[device_id]:
            del _open_streams[device_id]


async def _serve_stream(websocket: WebSocket, device_id: uuid.UUID, group_id: uuid.UUID) -> None:
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
                    if server_seq is None:
                        # The shared LISTEN connection dropped: close, and the client's
                        # reconnect-then-pull catches up on whatever it missed.
                        await websocket.close(code=status.WS_1012_SERVICE_RESTART)
                        return
                except TimeoutError:
                    server_seq = None
                # Revocation is re-checked before every frame — a signal and the idle
                # heartbeat alike. Checking only on the heartbeat let a busy group, which
                # never goes 30 s without a push, keep a revoked device's stream (and its
                # MAX_STREAMS_PER_DEVICE slot) open. One primary-key read per push.
                if await _is_revoked(device_id):
                    await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
                    return
                if server_seq is None:
                    # Heartbeat — keeps proxies (Caddy/Nginx) from closing idle conns.
                    await websocket.send_json({"type": "ping"})
                else:
                    await websocket.send_json({"type": "new_seq", "server_seq": server_seq})
        except WebSocketDisconnect:
            pass
        finally:
            receiver_task.cancel()
            with contextlib.suppress(asyncio.CancelledError):
                await receiver_task
