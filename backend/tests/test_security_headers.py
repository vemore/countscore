"""Tests for the security-header middleware and the body-size preconditions."""
from __future__ import annotations

import pytest

from app.config import get_settings
from app.main import create_app


@pytest.fixture
def _hsts_on(monkeypatch):
    """HSTS is opt-in; flip the setting and drop the lru_cache around it."""
    get_settings.cache_clear()
    monkeypatch.setenv("HSTS_ENABLED", "true")
    yield
    get_settings.cache_clear()


async def test_baseline_headers_are_present(client):
    r = await client.get("/health")

    assert r.status_code == 200
    assert r.headers["X-Content-Type-Options"] == "nosniff"
    assert r.headers["X-Frame-Options"] == "DENY"
    assert r.headers["Referrer-Policy"] == "no-referrer"
    assert r.headers["Cross-Origin-Opener-Policy"] == "same-origin"
    assert r.headers["Content-Security-Policy"] == "default-src 'none'; frame-ancestors 'none'"


async def test_hsts_is_absent_by_default(client):
    r = await client.get("/health")

    assert "Strict-Transport-Security" not in r.headers


async def test_docs_get_a_csp_that_lets_swagger_load(client):
    r = await client.get("/docs")

    csp = r.headers["Content-Security-Policy"]
    assert "default-src 'none'" not in csp
    assert "https://cdn.jsdelivr.net" in csp


async def test_hsts_is_sent_when_enabled(_hsts_on):
    from httpx import ASGITransport, AsyncClient

    app = create_app()
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        r = await ac.get("/health")

    assert r.headers["Strict-Transport-Security"] == "max-age=31536000; includeSubDomains"


async def test_post_without_content_length_is_refused(client):
    """A chunked body has no Content-Length, so the size cap could not be applied."""

    async def _chunks():
        yield b'{"name": "g"}'

    r = await client.post(
        "/groups", content=_chunks(), headers={"Content-Type": "application/json"}
    )

    assert r.status_code == 411


async def test_oversized_body_is_still_refused(client):
    settings = get_settings()
    body = {"name": "g", "device_label": "x" * (settings.max_body_bytes + 10)}

    r = await client.post("/groups", json=body)

    assert r.status_code == 413
