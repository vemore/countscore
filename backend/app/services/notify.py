"""Postgres LISTEN/NOTIFY broker for the sync WebSocket.

When a /sync/push commits a delta, it sends NOTIFY on channel ``group_<uuid>`` with
the new server_seq. WebSocket connections subscribe through ``listen_for_group`` and
re-emit the notification as ``{"type": "new_seq", "server_seq": N}`` to their client.

Why this and not Redis: the volume target is "tens to hundreds of groups, dozens of
concurrent devices per group". Postgres handles this in tens of µs per NOTIFY. Adding
Redis would be infrastructure for no real benefit at this scale.

**One connection for every stream.** Each stream used to open its own asyncpg
connection, so one device opening streams in a loop could exhaust ``max_connections``
for the whole service. The process now holds a single LISTEN connection and fans the
notifications out to in-process queues, one per stream. State is process-local, which
the single production worker already assumes (backend/CLAUDE.md, rule 2).

If that connection drops, every subscriber receives ``None`` and is expected to close
its stream: the client reconnects and pulls, so nothing is missed, and the next
subscriber opens a fresh connection.
"""

from __future__ import annotations

import asyncio
import json
import logging
import uuid
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any

import asyncpg
from sqlalchemy import text

from app.config import get_settings

logger = logging.getLogger(__name__)

# The connection's application_name, so it can be told apart in pg_stat_activity.
LISTEN_APPLICATION_NAME = "countscore-listen"

# ``None`` means "the broker lost its connection; close the stream".
StreamQueue = asyncio.Queue[int | None]


def _channel_for(group_id: uuid.UUID) -> str:
    # Channel names in Postgres are NAMEDATALEN-bound (63 chars); prefix + UUID fits.
    return f"group_{group_id.hex}"


async def notify_new_seq(session, group_id: uuid.UUID, server_seq: int) -> None:
    """Sends a NOTIFY in the current transaction. Must be called BEFORE commit."""
    payload = json.dumps({"server_seq": server_seq})
    # pg_notify is a function, so the channel binds as a parameter like any other
    # value. The subscribe side never builds SQL at all — asyncpg's add_listener takes
    # the channel as an argument. No string-built SQL anywhere in the codebase.
    await session.execute(
        text("SELECT pg_notify(:channel, :payload)"),
        {"channel": _channel_for(group_id), "payload": payload},
    )


class _Broker:
    def __init__(self) -> None:
        self._conn: Any = None
        self._lock = asyncio.Lock()
        self._loop: asyncio.AbstractEventLoop | None = None
        self._subscribers: dict[str, set[StreamQueue]] = {}

    def _bind_loop(self) -> None:
        """Start over on a new event loop: a connection and a lock belong to one loop.

        Production runs one loop for the process lifetime; tests run one per test.
        """
        loop = asyncio.get_running_loop()
        if loop is not self._loop:
            self._loop = loop
            self._conn = None
            self._lock = asyncio.Lock()
            self._subscribers = {}

    async def _connection(self) -> Any:
        if self._conn is None or self._conn.is_closed():
            # asyncpg uses its own DSN format (no driver prefix).
            dsn = get_settings().database_url.replace("postgresql+asyncpg://", "postgresql://")
            conn = await asyncpg.connect(
                dsn, server_settings={"application_name": LISTEN_APPLICATION_NAME}
            )
            conn.add_termination_listener(self._on_terminated)
            self._conn = conn
        return self._conn

    def _on_notify(self, _conn: Any, _pid: int, channel: str, payload: str) -> None:
        try:
            seq = int(json.loads(payload)["server_seq"])
        except (ValueError, KeyError, TypeError):
            return
        for queue in self._subscribers.get(channel, ()):
            queue.put_nowait(seq)

    def _on_terminated(self, conn: Any) -> None:
        if conn is not self._conn:
            return
        logger.warning("sync LISTEN connection lost; closing %d stream(s)", self._count())
        self._conn = None
        subscribers, self._subscribers = self._subscribers, {}
        for queues in subscribers.values():
            for queue in queues:
                queue.put_nowait(None)

    def _count(self) -> int:
        return sum(len(q) for q in self._subscribers.values())

    async def subscribe(self, channel: str) -> StreamQueue:
        self._bind_loop()
        queue: StreamQueue = asyncio.Queue()
        async with self._lock:
            conn = await self._connection()
            if channel not in self._subscribers:
                await conn.add_listener(channel, self._on_notify)
                self._subscribers[channel] = set()
            self._subscribers[channel].add(queue)
        return queue

    async def unsubscribe(self, channel: str, queue: StreamQueue) -> None:
        self._bind_loop()
        async with self._lock:
            queues = self._subscribers.get(channel)
            if queues is None or queue not in queues:
                return  # already dropped when the connection was lost
            queues.discard(queue)
            if queues:
                return
            del self._subscribers[channel]
            if self._conn is not None and not self._conn.is_closed():
                await self._conn.remove_listener(channel, self._on_notify)

    async def close(self) -> None:
        self._bind_loop()
        async with self._lock:
            conn, self._conn = self._conn, None
            self._subscribers = {}
            if conn is not None and not conn.is_closed():
                await conn.close()


_broker = _Broker()


@asynccontextmanager
async def listen_for_group(group_id: uuid.UUID) -> AsyncIterator[StreamQueue]:
    """Yields a queue receiving the group's new ``server_seq`` values, or ``None`` when the
    shared connection is lost and the stream should close."""
    channel = _channel_for(group_id)
    queue = await _broker.subscribe(channel)
    try:
        yield queue
    finally:
        await _broker.unsubscribe(channel, queue)


async def close_broker() -> None:
    """Close the shared LISTEN connection — application shutdown."""
    await _broker.close()
