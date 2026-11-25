"""/sync against stale, replayed and hostile input — one test per case.

Every test asserts the answer **and** that nothing else changed: no row written for a
rejected delta, no ``server_seq`` consumed, nothing new in any group's pull. ``_world``
snapshots every synced table, ``change_log`` and each group's ``last_server_seq``, so
"nothing else changed" is one equality.

SQLite fixtures, ``pg_notify`` stubbed. The cases only Postgres can show (a NUL byte, a
lone surrogate, two device rows of one install pushing at the same instant) are at the end
of ``test_sync_ws_integration.py``. Wip entry:
``wip/done/2026-11-25-sync-server-adversarial-api-tests.md``.
"""

from __future__ import annotations

import uuid
from typing import Any
from unittest.mock import AsyncMock

import pytest
from sqlalchemy import select


@pytest.fixture(autouse=True)
def _stub_notify(monkeypatch):
    from app.routes import sync as sync_route

    monkeypatch.setattr(sync_route, "notify_new_seq", AsyncMock(return_value=None))


# --- Helpers -----------------------------------------------------------------------


async def _group(client, name="g"):
    r = await client.post("/groups", json={"name": name, "device_label": "d"})
    assert r.status_code == 201, r.text
    body = r.json()
    return body, {"Authorization": f"Bearer {body['device']['token']}"}


async def _push(client, headers, *deltas):
    r = await client.post("/sync/push", json={"deltas": list(deltas)}, headers=headers)
    assert r.status_code == 200, r.text
    return r.json()


async def _pull(client, headers, since_seq=0):
    r = await client.get(f"/sync/pull?since_seq={since_seq}", headers=headers)
    assert r.status_code == 200, r.text
    return r.json()


def _delta(entity_type, entity_uuid, lamport, op="upsert", **payload):
    return {
        "entity_type": entity_type,
        "entity_uuid": str(entity_uuid),
        "op": op,
        "payload": payload,
        "client_lamport": lamport,
    }


def _statuses(body):
    return [(r["status"], r["reason"]) for r in body["results"]]


async def _world(session_factory) -> dict[str, Any]:
    """Every synced row, the whole log and each group's sequence, comparable by ``==``.

    Devices are left out: ``last_seen_at`` moves on every authenticated request.
    """
    from app.models import (
        ChangeLog,
        Game,
        GameAnalysis,
        GamePlayer,
        GameType,
        Group,
        Player,
        Round,
        Score,
    )

    world: dict[str, Any] = {}
    async with session_factory() as s:
        for cls in (
            Group,
            Player,
            GameType,
            Game,
            GamePlayer,
            Round,
            Score,
            GameAnalysis,
            ChangeLog,
        ):
            rows = (await s.execute(select(cls))).scalars().all()
            world[cls.__tablename__] = sorted(repr(sorted(r.model_dump().items())) for r in rows)
    return world


async def _get(session_factory, cls, entity_uuid):
    async with session_factory() as s:
        return await s.get(cls, uuid.UUID(str(entity_uuid)))


# --- Replay: a restored backup --------------------------------------------------


async def test_a_reused_lamport_with_another_payload_is_answered_duplicate(client, session_factory):
    """Pins today's behaviour: the second payload is dropped and the device is told
    its edit is on the server. A restore re-stamps lamports already used."""
    from app.models import Game

    _body, headers = await _group(client)
    game = uuid.uuid4()
    first = await _push(client, headers, _delta("game", game, 7, name="Before the backup"))
    before = await _world(session_factory)

    replay = await _push(client, headers, _delta("game", game, 7, name="After the restore"))

    assert _statuses(replay) == [("duplicate", None)]
    assert replay["results"][0]["server_seq"] == first["results"][0]["server_seq"]
    assert (await _get(session_factory, Game, game)).name == "Before the backup"
    assert await _world(session_factory) == before
