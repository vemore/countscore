"""The /sync/stream handler without Postgres: the per-device cap, a lost LISTEN connection
and a device revoked while its group keeps pushing.

``listen_for_group`` is replaced by an in-memory queue and ``_is_revoked`` by a set of
revoked device ids, so these run on the fast suite; the shared connection and the real
revocation read are covered by ``test_sync_ws_integration.py``.
"""

from __future__ import annotations

import asyncio
import uuid
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import pytest
from fastapi import WebSocketDisconnect, status

from app.config import get_settings
from app.routes import sync as sync_route
from app.services import ws_ticket


class FakeWebSocket:
    def __init__(self) -> None:
        self.accepted = asyncio.Event()
        self.closed = asyncio.Event()
        self.close_code: int | None = None
        self._gone = asyncio.Event()
        self.sent: list[dict] = []

    async def accept(self) -> None:
        self.accepted.set()

    async def close(self, code: int) -> None:
        self.close_code = code
        self.closed.set()

    async def receive_text(self) -> str:
        await self._gone.wait()
        raise WebSocketDisconnect()

    async def send_json(self, data: dict) -> None:
        self.sent.append(data)

    def disconnect(self) -> None:
        self._gone.set()


@pytest.fixture
def revoked(monkeypatch) -> set[uuid.UUID]:
    ids: set[uuid.UUID] = set()

    async def fake_is_revoked(device_id: uuid.UUID) -> bool:
        return device_id in ids

    monkeypatch.setattr(sync_route, "_is_revoked", fake_is_revoked)
    return ids


@pytest.fixture
def queues(monkeypatch, revoked) -> list[asyncio.Queue]:
    opened: list[asyncio.Queue] = []

    @asynccontextmanager
    async def fake_listen(_group_id: uuid.UUID) -> AsyncIterator[asyncio.Queue]:
        queue: asyncio.Queue = asyncio.Queue()
        opened.append(queue)
        yield queue

    monkeypatch.setattr(sync_route, "listen_for_group", fake_listen)
    return opened


async def _open(device_id: uuid.UUID, group_id: uuid.UUID) -> tuple[FakeWebSocket, asyncio.Task]:
    ws = FakeWebSocket()
    ticket = ws_ticket.issue(device_id, group_id)
    task = asyncio.create_task(sync_route.stream(ws, ticket))  # type: ignore[arg-type]
    await asyncio.wait(
        [asyncio.ensure_future(ws.accepted.wait()), asyncio.ensure_future(ws.closed.wait())],
        return_when=asyncio.FIRST_COMPLETED,
    )
    return ws, task


async def _hang_up(ws: FakeWebSocket, task: asyncio.Task, queue: asyncio.Queue) -> None:
    ws.disconnect()
    queue.put_nowait(1)  # wakes the loop, which then notices the receiver has ended
    await asyncio.wait_for(task, timeout=2)


async def test_a_device_holds_at_most_the_configured_streams(queues):
    limit = get_settings().max_streams_per_device
    device, group = uuid.uuid4(), uuid.uuid4()

    streams = [await _open(device, group) for _ in range(limit)]
    assert all(ws.accepted.is_set() for ws, _ in streams)

    refused, task = await _open(device, group)
    await asyncio.wait_for(task, timeout=2)
    assert not refused.accepted.is_set()
    assert refused.close_code == status.WS_1013_TRY_AGAIN_LATER
    assert len(queues) == limit  # refused before it subscribed to anything

    # Another device of the same group is not affected.
    other, other_task = await _open(uuid.uuid4(), group)
    assert other.accepted.is_set()

    # Closing one stream frees its place.
    ws, t = streams[0]
    await _hang_up(ws, t, queues[0])
    again, again_task = await _open(device, group)
    assert again.accepted.is_set()

    for (ws, t), q in zip(
        [*streams[1:], (other, other_task), (again, again_task)], queues[1:], strict=True
    ):
        await _hang_up(ws, t, q)
    assert sync_route._open_streams == {}


async def test_a_lost_listen_connection_closes_the_stream(queues):
    ws, task = await _open(uuid.uuid4(), uuid.uuid4())
    assert ws.accepted.is_set()

    queues[0].put_nowait(None)
    await asyncio.wait_for(task, timeout=2)

    assert ws.close_code == status.WS_1012_SERVICE_RESTART
    assert sync_route._open_streams == {}


async def test_a_device_revoked_while_its_group_pushes_is_closed_at_the_next_signal(
    queues, revoked
):
    """The idle heartbeat never fires while signals keep coming, so it cannot be the only check."""
    device = uuid.uuid4()
    ws, task = await _open(device, uuid.uuid4())
    assert ws.accepted.is_set()

    queues[0].put_nowait(1)
    for _ in range(20):
        if ws.sent:
            break
        await asyncio.sleep(0.01)
    assert ws.sent == [{"type": "new_seq", "server_seq": 1}]

    revoked.add(device)
    queues[0].put_nowait(2)
    await asyncio.wait_for(task, timeout=2)  # well under the 30 s idle heartbeat

    assert ws.close_code == status.WS_1008_POLICY_VIOLATION
    assert ws.sent == [{"type": "new_seq", "server_seq": 1}]  # 2 was never forwarded
    assert sync_route._open_streams == {}
