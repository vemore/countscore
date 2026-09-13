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

    async def push_games(token: str) -> list[int]:
        deltas = [
            {
                "entity_type": "game",
                "entity_uuid": str(uuid.uuid4()),
                "op": "upsert",
                "payload": {"name": f"G{i}"},
                "client_lamport": i + 1,
            }
            for i in range(20)
        ]
        resp = await pg_client.post(
            "/sync/push",
            json={"deltas": deltas},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200, resp.text
        return [x["server_seq"] for x in resp.json()["results"]]

    seqs = await asyncio.gather(*(push_games(t) for t in tokens * 2))

    flat = sorted(s for batch in seqs for s in batch)
    # Lamports repeat per device across the two rounds, so half the deltas are duplicates
    # that echo an earlier seq; the distinct values must still be exactly 1..40.
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
