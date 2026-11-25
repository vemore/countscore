"""Integration tests for /sync/stream (WebSocket + real Postgres LISTEN/NOTIFY).

Spin up a Postgres container via testcontainers and run the full
  push → NOTIFY → WS client receives new_seq → pull
path without stubbing pg_notify.

Marked ``@pytest.mark.integration``. Auto-skipped when Docker is unavailable.
"""

from __future__ import annotations

import asyncio
import contextlib
import json
import os
import subprocess
import uuid
from collections.abc import AsyncIterator

import pytest
import pytest_asyncio
from httpx import AsyncClient
from httpx_ws.transport import ASGIWebSocketTransport  # type: ignore[import]
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlmodel import SQLModel

# ---------------------------------------------------------------------------
# Docker guard
# ---------------------------------------------------------------------------


def _docker_available() -> bool:
    try:
        return subprocess.run(["docker", "info"], capture_output=True, timeout=5).returncode == 0
    except Exception:
        return False


pytestmark = pytest.mark.integration


# ---------------------------------------------------------------------------
# Fixtures — all function-scoped to avoid asyncpg shared-connection bugs
# ---------------------------------------------------------------------------


@pytest.fixture(scope="session")
def postgres_container():
    """Start one Postgres container for the session and create the schema."""
    if not _docker_available():
        pytest.skip("Docker not available — skipping Postgres integration tests")

    from testcontainers.community.postgres import PostgresContainer  # type: ignore[import]

    with PostgresContainer("postgres:17-alpine") as pg:
        host = pg.get_container_host_ip()
        port = pg.get_exposed_port(5432)
        user = pg.username
        password = pg.password
        db = pg.dbname
        dsn = f"postgresql+asyncpg://{user}:{password}@{host}:{port}/{db}"
        yield dsn


@pytest_asyncio.fixture
async def pg_engine(postgres_container):
    """Fresh async engine per test — avoids connection-state sharing."""
    eng = create_async_engine(postgres_container, echo=False)
    async with eng.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)
    yield eng
    # Teardown errors from anyio cancel-scope mismatch are harmless.
    with contextlib.suppress(Exception):
        await eng.dispose()


@pytest_asyncio.fixture
async def pg_client(postgres_container, pg_engine) -> AsyncIterator[AsyncClient]:
    """HTTP test client wired to the real Postgres.

    We must patch AsyncSessionLocal in the sync *route* module (not just in
    app.db) because `from app.db import AsyncSessionLocal` creates a local
    binding in sync.py that bypasses any replacement of db_module.AsyncSessionLocal.
    """
    os.environ["DATABASE_URL"] = postgres_container

    from app import db as db_module
    from app.config import get_settings
    from app.main import create_app
    from app.routes import sync as sync_route

    get_settings.cache_clear()

    session_factory = async_sessionmaker(pg_engine, class_=AsyncSession, expire_on_commit=False)

    app = create_app()

    async def _get_session_override() -> AsyncIterator[AsyncSession]:
        async with session_factory() as s:
            yield s

    app.dependency_overrides[db_module.get_session] = _get_session_override
    # Patch the local binding in sync.py (used by the WS handler).
    original_sl = sync_route.AsyncSessionLocal
    sync_route.AsyncSessionLocal = session_factory  # type: ignore[assignment]
    db_module.AsyncSessionLocal = session_factory  # type: ignore[assignment]

    transport = ASGIWebSocketTransport(app=app)
    ac = AsyncClient(transport=transport, base_url="http://test")
    await ac.__aenter__()
    yield ac
    # anyio cancel-scope teardown in a different task — harmless.
    with contextlib.suppress(RuntimeError):
        await ac.__aexit__(None, None, None)

    sync_route.AsyncSessionLocal = original_sl  # restore
    db_module.AsyncSessionLocal = original_sl

    # The shared LISTEN connection belongs to this test's event loop.
    from app.services.notify import close_broker

    await close_broker()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


async def _make_group_and_token(client: AsyncClient) -> tuple[str, str]:
    r = await client.post(
        "/groups", json={"name": f"ws-test-{uuid.uuid4().hex[:8]}", "device_label": "d"}
    )
    assert r.status_code == 201, r.text
    body = r.json()
    return body["group"]["id"], body["device"]["token"]


async def _ws_url(client, token: str) -> str:
    """Trade the device token for a single-use handshake ticket."""
    r = await client.post("/sync/ws-ticket", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200, r.text
    return f"http://test/sync/stream?ticket={r.json()['ticket']}"


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


async def test_ws_receives_new_seq_after_push(pg_client):
    """push → pg_notify → WS client receives {"type":"new_seq","server_seq":1}."""
    _group_id, token = await _make_group_and_token(pg_client)
    headers = {"Authorization": f"Bearer {token}"}
    ws_url = await _ws_url(pg_client, token)

    from httpx_ws import aconnect_ws  # type: ignore[import]

    player_uuid = str(uuid.uuid4())
    delta = {
        "entity_type": "player",
        "entity_uuid": player_uuid,
        "op": "upsert",
        "payload": {"name": "WS-Alice", "name_normalized": "ws-alice"},
        "client_lamport": 1,
    }

    async with aconnect_ws(ws_url, pg_client) as ws:
        push_r = await pg_client.post("/sync/push", json={"deltas": [delta]}, headers=headers)
        assert push_r.status_code == 200, push_r.text
        server_seq = push_r.json()["server_seq_max"]
        assert server_seq >= 1

        msg = json.loads(await asyncio.wait_for(ws.receive_text(), timeout=5.0))
        assert msg["type"] == "new_seq"
        assert msg["server_seq"] == server_seq


async def test_ws_push_pull_full_cycle(pg_client):
    """push → WS notified → pull returns the delta."""
    _group_id, token = await _make_group_and_token(pg_client)
    headers = {"Authorization": f"Bearer {token}"}
    ws_url = await _ws_url(pg_client, token)

    from httpx_ws import aconnect_ws  # type: ignore[import]

    game_uuid = str(uuid.uuid4())
    delta = {
        "entity_type": "game",
        "entity_uuid": game_uuid,
        "op": "upsert",
        "payload": {"name": "WS-Game", "is_lowest_score_wins": False},
        "client_lamport": 10,
    }

    async with aconnect_ws(ws_url, pg_client) as ws:
        push_r = await pg_client.post("/sync/push", json={"deltas": [delta]}, headers=headers)
        assert push_r.status_code == 200, push_r.text

        msg = json.loads(await asyncio.wait_for(ws.receive_text(), timeout=5.0))
        assert msg["type"] == "new_seq"
        notified_seq = msg["server_seq"]

    pull_r = await pg_client.get(f"/sync/pull?since_seq={notified_seq - 1}", headers=headers)
    assert pull_r.status_code == 200, pull_r.text
    deltas = pull_r.json()["deltas"]
    assert any(d["entity_uuid"] == game_uuid for d in deltas)


# ---------------------------------------------------------------------------
# Postgres-only halves of the sync contract (see tests/test_sync_contract.py)
# ---------------------------------------------------------------------------


async def test_opaque_argb_colours_fit_on_postgres(pg_client):
    """int4 overflowed at 0x80000000; every opaque Flutter colour is above it."""
    _group_id, token = await _make_group_and_token(pg_client)
    headers = {"Authorization": f"Bearer {token}"}
    player = str(uuid.uuid4())

    r = await pg_client.post(
        "/sync/push",
        json={
            "deltas": [
                {
                    "entity_type": "player",
                    "entity_uuid": player,
                    "op": "upsert",
                    "payload": {
                        "name": "Ambre",
                        "name_normalized": "ambre",
                        "color_value": 0xFFFFC107,
                    },
                    "client_lamport": 1,
                },
                {
                    "entity_type": "game_type",
                    "entity_uuid": str(uuid.uuid4()),
                    "op": "upsert",
                    "payload": {
                        "name": "ZapZap",
                        "icon_code_point": 0xE000,
                        "card_color_value": 0xFFFFFFFF,
                    },
                    "client_lamport": 2,
                },
            ]
        },
        headers=headers,
    )

    assert r.status_code == 200, r.text
    assert [x["status"] for x in r.json()["results"]] == ["applied", "applied"]


async def test_concurrent_pushes_to_one_group_get_distinct_server_seqs(pg_client):
    r = await pg_client.post(
        "/groups", json={"name": f"race-{uuid.uuid4().hex[:8]}", "device_label": "A"}
    )
    created = r.json()
    r = await pg_client.post(
        "/groups/join",
        json={"share_token": created["group"]["share_token"], "device_label": "B"},
    )
    tokens = [created["device"]["token"], r.json()["device"]["token"]]
    # One batch per device, each pushed twice at once: the second is a network retry
    # racing the first. (Another payload under the same lamports is `lamport_reused`.)
    batches = {
        token: [
            {
                "entity_type": "game",
                "entity_uuid": str(uuid.uuid4()),
                "op": "upsert",
                "payload": {"name": f"G{i}"},
                "client_lamport": i + 1,
            }
            for i in range(20)
        ]
        for token in tokens
    }

    async def push_games(token: str) -> list[int]:
        resp = await pg_client.post(
            "/sync/push",
            json={"deltas": batches[token]},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200, resp.text
        return [x["server_seq"] for x in resp.json()["results"]]

    seqs = await asyncio.gather(*(push_games(t) for t in tokens * 2))

    flat = sorted(s for batch in seqs for s in batch)
    # Each delta reaches the server twice, so half the answers are duplicates that echo
    # an earlier seq; the distinct values must still be exactly 1..40.
    assert sorted(set(flat)) == list(range(1, 41))
    pull = await pg_client.get(
        "/sync/pull?since_seq=0&limit=2000",
        headers={"Authorization": f"Bearer {tokens[0]}"},
    )
    assert [d["server_seq"] for d in pull.json()["deltas"]] == list(range(1, 41))


async def test_streams_share_one_listen_connection(pg_client, pg_engine):
    """One Postgres connection per stream let a single device exhaust max_connections."""
    from httpx_ws import aconnect_ws  # type: ignore[import]
    from sqlalchemy import text

    from app.services.notify import LISTEN_APPLICATION_NAME

    _g1, token1 = await _make_group_and_token(pg_client)
    _g2, token2 = await _make_group_and_token(pg_client)
    headers2 = {"Authorization": f"Bearer {token2}"}
    delta = {
        "entity_type": "player",
        "entity_uuid": str(uuid.uuid4()),
        "op": "upsert",
        "payload": {"name": "Shared", "name_normalized": "shared"},
        "client_lamport": 1,
    }

    async with (
        aconnect_ws(await _ws_url(pg_client, token1), pg_client) as a,
        aconnect_ws(await _ws_url(pg_client, token2), pg_client) as b,
        aconnect_ws(await _ws_url(pg_client, token2), pg_client) as c,
    ):
        async with pg_engine.connect() as conn:
            listeners = (
                await conn.execute(
                    text("SELECT count(*) FROM pg_stat_activity WHERE application_name = :n"),
                    {"n": LISTEN_APPLICATION_NAME},
                )
            ).scalar_one()
        assert listeners == 1

        push = await pg_client.post("/sync/push", json={"deltas": [delta]}, headers=headers2)
        assert push.status_code == 200, push.text
        seq = push.json()["server_seq_max"]

        # Both streams of group 2 hear it; group 1's stream does not.
        for ws in (b, c):
            msg = json.loads(await asyncio.wait_for(ws.receive_text(), timeout=5.0))
            assert msg == {"type": "new_seq", "server_seq": seq}
        with pytest.raises(TimeoutError):
            await asyncio.wait_for(a.receive_text(), timeout=1.0)


async def test_a_device_revoked_while_its_group_pushes_loses_its_stream(pg_client):
    """Revocation used to be re-checked only after 30 s without a signal, so a busy group
    kept the revoked device's stream — and its MAX_STREAMS_PER_DEVICE slot — alive."""
    from fastapi import status
    from httpx_ws import WebSocketDisconnect, aconnect_ws  # type: ignore[import]

    from app.routes import sync as sync_route

    r = await pg_client.post(
        "/groups", json={"name": f"revoke-{uuid.uuid4().hex[:8]}", "device_label": "A"}
    )
    created = r.json()
    alice = {"Authorization": f"Bearer {created['device']['token']}"}
    r = await pg_client.post(
        "/groups/join",
        json={"share_token": created["group"]["share_token"], "device_label": "B"},
    )
    bob = r.json()["device"]
    bob_id = uuid.UUID(bob["id"])

    def delta(lamport: int) -> dict:
        return {
            "entity_type": "player",
            "entity_uuid": str(uuid.uuid4()),
            "op": "upsert",
            "payload": {"name": f"P{lamport}", "name_normalized": f"p{lamport}"},
            "client_lamport": lamport,
        }

    async with aconnect_ws(await _ws_url(pg_client, bob["token"]), pg_client) as ws:
        push = await pg_client.post("/sync/push", json={"deltas": [delta(1)]}, headers=alice)
        assert push.status_code == 200, push.text
        msg = json.loads(await asyncio.wait_for(ws.receive_text(), timeout=5.0))
        assert msg["type"] == "new_seq"

        r = await pg_client.post(f"/groups/me/devices/{bob_id}/revoke", headers=alice)
        assert r.status_code == 200, r.text

        push = await pg_client.post("/sync/push", json={"deltas": [delta(2)]}, headers=alice)
        assert push.status_code == 200, push.text
        # Well under the 30 s idle heartbeat: the signal itself must close the stream.
        with pytest.raises(WebSocketDisconnect) as closed:
            await asyncio.wait_for(ws.receive_text(), timeout=5.0)
        assert closed.value.code == status.WS_1008_POLICY_VIOLATION

    # The slot is given back once the handler has unwound.
    for _ in range(50):
        if bob_id not in sync_route._open_streams:
            break
        await asyncio.sleep(0.05)
    assert bob_id not in sync_route._open_streams


# ---------------------------------------------------------------------------
# Postgres-only halves of the adversarial cases (see tests/test_sync_adversarial.py)
# ---------------------------------------------------------------------------


def _pg_delta(entity_type: str, entity_uuid, lamport: int, op: str = "upsert", **payload):
    return {
        "entity_type": entity_type,
        "entity_uuid": str(entity_uuid),
        "op": op,
        "payload": payload,
        "client_lamport": lamport,
    }


async def _pg_push_raw(client: AsyncClient, token: str, body: str) -> dict:
    """``body`` as typed: JSON escapes such as a lone ``\\ud800`` reach the server as is."""
    r = await client.post(
        "/sync/push",
        content=body,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )
    assert r.status_code == 200, r.text
    return r.json()


async def _pg_log(client: AsyncClient, token: str) -> list[dict]:
    r = await client.get(
        "/sync/pull?since_seq=0&limit=2000", headers={"Authorization": f"Bearer {token}"}
    )
    assert r.status_code == 200, r.text
    return r.json()["deltas"]


@pytest.mark.parametrize(
    ("entity_type", "payload_json", "reason"),
    [
        ("game", '{"name": "a\\u0000b"}', "name contains a NUL character"),
        ("game", '{"name": "a\\ud800b"}', "name is not valid UTF-8"),
        (
            "game_type",
            '{"name": "T", "icon_code_point": 1, "card_color_value": 1, "rules": "x\\u0000"}',
            "rules contains a NUL character",
        ),
        (
            "game_analysis",
            '{"game_id": "GAME", "content": "x", "model_id": "m\\udfff"}',
            "model_id is not valid UTF-8",
        ),
    ],
)
async def test_a_string_postgres_cannot_store_is_one_rejected_delta(
    pg_client, entity_type, payload_json, reason
):
    """A NUL byte and a lone surrogate parse as JSON, and SQLite stores both; Postgres
    refuses them in a text column and in the jsonb log, and the push answered 500."""
    _group_id, token = await _make_group_and_token(pg_client)
    game = uuid.uuid4()
    seeded = json.dumps({"deltas": [_pg_delta("game", game, 1, name="G")]})
    await _pg_push_raw(pg_client, token, seeded)
    before = await _pg_log(pg_client, token)

    bad = (
        f'{{"entity_type": "{entity_type}", "entity_uuid": "{uuid.uuid4()}", "op": "upsert",'
        f' "client_lamport": 2, "payload": {payload_json.replace("GAME", str(game))}}}'
    )
    sibling = json.dumps(_pg_delta("game", uuid.uuid4(), 3, name="Sibling"))
    body = await _pg_push_raw(pg_client, token, f'{{"deltas": [{bad}, {sibling}]}}')

    assert [(x["status"], x["reason"]) for x in body["results"]] == [
        ("rejected", reason),
        ("applied", None),
    ]
    assert body["results"][1]["server_seq"] == 2  # the rejected delta consumed no seq
    after = await _pg_log(pg_client, token)
    assert after[: len(before)] == before
    assert [d["payload"].get("name") for d in after[len(before) :]] == ["Sibling"]


async def test_the_data_error_backstop_rejects_one_delta_on_postgres(pg_client, monkeypatch):
    """With the value checks off, the database's own refusal is one rejected delta — the
    savepoint undoes it alone — and never a 500."""
    from app.routes import sync as sync_route

    monkeypatch.setattr(sync_route, "_value_problem", lambda cls, payload: None)
    _group_id, token = await _make_group_and_token(pg_client)
    before = json.dumps(_pg_delta("game", uuid.uuid4(), 1, name="Before"))
    after = json.dumps(_pg_delta("game", uuid.uuid4(), 3, name="After"))
    nul = (
        f'{{"entity_type": "game", "entity_uuid": "{uuid.uuid4()}", "op": "upsert",'
        ' "client_lamport": 2, "payload": {"name": "a\\u0000b"}}'
    )

    body = await _pg_push_raw(pg_client, token, f'{{"deltas": [{before}, {nul}, {after}]}}')

    assert [(x["status"], x["reason"]) for x in body["results"]] == [
        ("applied", None),
        ("rejected", "invalid value"),
        ("applied", None),
    ]
    assert [d["payload"]["name"] for d in await _pg_log(pg_client, token)] == ["Before", "After"]


async def test_a_retry_is_a_duplicate_after_a_jsonb_round_trip(pg_client):
    """``lamport_reused`` compares the payload with the one the log holds. jsonb reorders
    keys and re-encodes numbers; a true retry must still compare equal."""
    _group_id, token = await _make_group_and_token(pg_client)
    game_type = uuid.uuid4()
    payload = {
        "rules": "Règles — 規則",
        "name": "Ünïcødé",
        "card_color_value": 0xFFFFFFFF,
        "icon_code_point": 0xE000,
        "is_lowest_score_wins": True,
        "player_dead_threshold": -1_000_000,
        "game_over_condition_type": None,
        "keypad_shortcut": '{"kind":"multiply","amount":2}',
        "builtin_key": "zapzap",
    }

    def push_body(p: dict) -> str:
        return json.dumps({"deltas": [_pg_delta("game_type", game_type, 1, **p)]})

    first = await _pg_push_raw(pg_client, token, push_body(payload))
    retry = await _pg_push_raw(pg_client, token, push_body(dict(reversed(payload.items()))))
    changed = await _pg_push_raw(pg_client, token, push_body({**payload, "name": "Autre"}))

    assert first["results"][0]["status"] == "applied"
    assert [(x["status"], x["server_seq"]) for x in retry["results"]] == [("duplicate", 1)]
    assert [(x["status"], x["reason"]) for x in changed["results"]] == [
        ("rejected", "lamport_reused")
    ]
    [logged] = await _pg_log(pg_client, token)
    assert logged["payload"]["name"] == "Ünïcødé"


async def test_two_device_rows_of_one_install_push_to_two_groups_at_once(pg_client):
    """An install in two groups holds one device row in each, and stamps lamports from one
    clock per group: the two may well send the same lamports at the same instant. Each
    group's row lock serialises its own pushes only; neither blocks nor dedups the other."""
    _a_id, a = await _make_group_and_token(pg_client)
    _b_id, b = await _make_group_and_token(pg_client)
    batches = {
        token: [_pg_delta("game", uuid.uuid4(), i + 1, name=f"G{i}") for i in range(30)]
        for token in (a, b)
    }

    async def push(token: str) -> list[tuple[str, int]]:
        resp = await pg_client.post(
            "/sync/push",
            json={"deltas": batches[token]},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200, resp.text
        return [(x["status"], x["server_seq"]) for x in resp.json()["results"]]

    a_res, b_res = await asyncio.gather(push(a), push(b))

    assert a_res == b_res == [("applied", i) for i in range(1, 31)]
    for token in (a, b):
        log = await _pg_log(pg_client, token)
        assert [d["entity_uuid"] for d in log] == [d["entity_uuid"] for d in batches[token]]
        assert [d["server_seq"] for d in log] == list(range(1, 31))
