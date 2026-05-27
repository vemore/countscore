"""Tests for /sync/push and /sync/pull.

We bypass the WebSocket NOTIFY (Postgres-only) since tests run on SQLite.
"""
from __future__ import annotations

import uuid
from unittest.mock import AsyncMock

import pytest


@pytest.fixture(autouse=True)
def _stub_notify(monkeypatch):
    """SQLite test DB doesn't support pg_notify — stub it out.

    We patch the symbol where it is *used* (app.routes.sync) rather than where it
    is defined (app.services.notify), because the route did `from … import notify_new_seq`
    which creates a local binding.
    """
    from app.routes import sync as sync_route
    monkeypatch.setattr(sync_route, "notify_new_seq", AsyncMock(return_value=None))


async def _make_group_and_token(client):
    r = await client.post("/groups", json={"name": "g", "device_label": "d"})
    body = r.json()
    return body["group"]["id"], body["device"]["token"]


async def test_push_pull_round_trip(client):
    group_id, token = await _make_group_and_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    player_uuid = str(uuid.uuid4())
    r = await client.post(
        "/sync/push",
        json={
            "deltas": [
                {
                    "entity_type": "player",
                    "entity_uuid": player_uuid,
                    "op": "upsert",
                    "payload": {
                        "name": "Alice",
                        "name_normalized": "alice",
                        "color_value": 4286611584,
                    },
                    "client_lamport": 1,
                }
            ]
        },
        headers=headers,
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["results"][0]["status"] == "applied"
    assert body["server_seq_max"] == 1

    # Pull from seq=0 returns the delta
    r = await client.get("/sync/pull?since_seq=0", headers=headers)
    assert r.status_code == 200
    body = r.json()
    assert len(body["deltas"]) == 1
    assert body["deltas"][0]["entity_uuid"] == player_uuid
    assert body["deltas"][0]["payload"]["name"] == "Alice"

    # Pull from seq=1 is empty
    r = await client.get("/sync/pull?since_seq=1", headers=headers)
    assert r.json()["deltas"] == []


async def test_push_idempotence(client):
    """Resending the same (device, lamport) returns duplicate, not double-applied."""
    group_id, token = await _make_group_and_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    delta = {
        "entity_type": "player",
        "entity_uuid": str(uuid.uuid4()),
        "op": "upsert",
        "payload": {"name": "Bob", "name_normalized": "bob"},
        "client_lamport": 7,
    }
    r1 = await client.post("/sync/push", json={"deltas": [delta]}, headers=headers)
    assert r1.json()["results"][0]["status"] == "applied"

    r2 = await client.post("/sync/push", json={"deltas": [delta]}, headers=headers)
    assert r2.json()["results"][0]["status"] == "duplicate"
    # Same server_seq returned
    assert r1.json()["server_seq_max"] == r2.json()["results"][0]["server_seq"]


async def test_round_uniqueness_rejected(client):
    """Two rounds with the same (game_id, round_number) → second is rejected."""
    group_id, token = await _make_group_and_token(client)
    headers = {"Authorization": f"Bearer {token}"}

    # Create a game first
    game_uuid = str(uuid.uuid4())
    await client.post(
        "/sync/push",
        json={
            "deltas": [
                {
                    "entity_type": "game",
                    "entity_uuid": game_uuid,
                    "op": "upsert",
                    "payload": {
                        "name": "Test",
                        "is_lowest_score_wins": True,
                        "started_at": "2026-05-27T10:00:00+00:00",
                    },
                    "client_lamport": 1,
                }
            ]
        },
        headers=headers,
    )

    # First round 1 — should succeed
    round_a = {
        "entity_type": "round",
        "entity_uuid": str(uuid.uuid4()),
        "op": "upsert",
        "payload": {"game_id": game_uuid, "round_number": 1},
        "client_lamport": 2,
    }
    r = await client.post("/sync/push", json={"deltas": [round_a]}, headers=headers)
    assert r.json()["results"][0]["status"] == "applied", r.json()

    # Second round 1 (different uuid, same number) — should be rejected
    round_b = {
        "entity_type": "round",
        "entity_uuid": str(uuid.uuid4()),
        "op": "upsert",
        "payload": {"game_id": game_uuid, "round_number": 1},
        "client_lamport": 3,
    }
    r = await client.post("/sync/push", json={"deltas": [round_b]}, headers=headers)
    assert r.json()["results"][0]["status"] == "rejected"


async def test_pull_requires_auth(client):
    r = await client.get("/sync/pull")
    assert r.status_code == 401
