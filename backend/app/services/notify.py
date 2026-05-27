"""Postgres LISTEN/NOTIFY broker for the sync WebSocket.

When a /sync/push commits a delta, it sends NOTIFY on channel ``group_<uuid>`` with
the new server_seq. WebSocket connections subscribe via LISTEN and re-emit the
notification as ``{"type": "new_seq", "server_seq": N}`` to their client.

Why this and not Redis: the volume target is "tens to hundreds of groups, dozens of
concurrent devices per group". Postgres handles this in tens of µs per NOTIFY. Adding
Redis would be infrastructure for no real benefit at this scale.
"""
from __future__ import annotations

import asyncio
import json
import uuid
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import asyncpg
from sqlalchemy import text

from app.config import get_settings


def _channel_for(group_id: uuid.UUID) -> str:
    # Channel names in Postgres are NAMEDATALEN-bound (63 chars); prefix + UUID fits.
    return f"group_{group_id.hex}"


async def notify_new_seq(session, group_id: uuid.UUID, server_seq: int) -> None:
    """Sends a NOTIFY in the current transaction. Must be called BEFORE commit."""
    payload = json.dumps({"server_seq": server_seq})
    # The channel name is built from a UUID (hex only) so f-string interpolation is safe;
    # the payload is parameterized.
    await session.execute(
        text(f"SELECT pg_notify('{_channel_for(group_id)}', :payload)"),
        {"payload": payload},
    )


@asynccontextmanager
async def listen_for_group(group_id: uuid.UUID) -> AsyncIterator[asyncio.Queue[int]]:
    """Async context manager. Yields a queue that receives ``server_seq`` ints as they arrive."""
    settings = get_settings()
    # asyncpg uses its own DSN format (no driver prefix).
    dsn = settings.database_url.replace("postgresql+asyncpg://", "postgresql://")
    conn = await asyncpg.connect(dsn)
    queue: asyncio.Queue[int] = asyncio.Queue()
    channel = _channel_for(group_id)

    def _on_notify(_conn, _pid, _channel, payload: str) -> None:
        try:
            data = json.loads(payload)
            seq = int(data["server_seq"])
        except (ValueError, KeyError, TypeError):
            return
        queue.put_nowait(seq)

    await conn.add_listener(channel, _on_notify)
    try:
        yield queue
    finally:
        await conn.remove_listener(channel, _on_notify)
        await conn.close()
