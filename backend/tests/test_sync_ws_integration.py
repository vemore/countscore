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
        return subprocess.run(
            ["docker", "info"], capture_output=True, timeout=5
        ).returncode == 0
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

    session_factory = async_sessionmaker(
        pg_engine, class_=AsyncSession, expire_on_commit=False
    )

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
        push_r = await pg_client.post(
            "/sync/push", json={"deltas": [delta]}, headers=headers
        )
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
        push_r = await pg_client.post(
            "/sync/push", json={"deltas": [delta]}, headers=headers
        )
        assert push_r.status_code == 200, push_r.text

        msg = json.loads(await asyncio.wait_for(ws.receive_text(), timeout=5.0))
        assert msg["type"] == "new_seq"
        notified_seq = msg["server_seq"]

    pull_r = await pg_client.get(
        f"/sync/pull?since_seq={notified_seq - 1}", headers=headers
    )
    assert pull_r.status_code == 200, pull_r.text
    deltas = pull_r.json()["deltas"]
    assert any(d["entity_uuid"] == game_uuid for d in deltas)
