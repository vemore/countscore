"""Pytest fixtures: spawn an in-memory SQLite for fast unit tests.

For Postgres-specific features (JSONB, pg_notify, UUID column type) we use the
SQLite-compatible fallbacks SQLModel provides automatically. The integration tests
that exercise the real Postgres features (NOTIFY, jsonb queries) should run against
a real Postgres via docker-compose in CI.
"""
from __future__ import annotations

import os
import uuid
from collections.abc import AsyncIterator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlmodel import SQLModel

os.environ.setdefault("ANTHROPIC_API_KEY", "")  # tests can run without it; MVP/group tests skip
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")

# Import after env is set
from app import db as db_module  # noqa: E402
from app.main import create_app  # noqa: E402

# Ensure models are loaded before metadata creation
from app import models  # noqa: F401, E402


@pytest.fixture(autouse=True)
def _reset_ip_rate_limiter():
    """The IP limiter holds process-global state; clear it between tests."""
    from app.services import ip_rate_limiter
    ip_rate_limiter.reset()
    yield
    ip_rate_limiter.reset()


@pytest_asyncio.fixture
async def engine():
    eng = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with eng.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)
    yield eng
    await eng.dispose()


@pytest_asyncio.fixture
async def session_factory(engine):
    return async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


@pytest_asyncio.fixture
async def session(session_factory) -> AsyncIterator[AsyncSession]:
    async with session_factory() as s:
        yield s


@pytest_asyncio.fixture
async def client(engine, session_factory) -> AsyncIterator[AsyncClient]:
    app = create_app()

    async def _get_session_override() -> AsyncIterator[AsyncSession]:
        async with session_factory() as s:
            yield s

    app.dependency_overrides[db_module.get_session] = _get_session_override

    # Also patch the module-level AsyncSessionLocal so the WS handshake uses our test DB.
    db_module.AsyncSessionLocal = session_factory  # type: ignore[assignment]

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
