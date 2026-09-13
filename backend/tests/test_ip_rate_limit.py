"""Tests for the per-IP throttle on the public LLM endpoints and the body-size cap."""

from __future__ import annotations

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from unittest.mock import AsyncMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.config import get_settings
from app.services.llm import LLMResult


def _payload() -> dict:
    return {
        "game": {
            "id": 1,
            "name": "Soirée ZapZap",
            "is_lowest_score_wins": True,
            "created_at": "2026-05-01T20:30:00.000",
        },
        "game_type": "ZapZap",
        "players": [{"id": 1, "name": "Nadia"}],
        "rounds": [
            {"id": 1, "number": 1, "comment": None, "scores": [{"player_id": 1, "value": 0}]}
        ],
        "history_by_player_name": {"Nadia": []},
    }


@pytest.fixture
def client_from(client):
    """Open a client whose requests arrive from ``ip`` — the address the app rate-limits on.

    Shares the app, and so the test database, of the ``client`` fixture; only the ASGI
    peer differs. That is what a distinct caller looks like to the app in production,
    and nothing else may look like one: a header must not.
    """
    app = client._transport.app

    @asynccontextmanager
    async def _open(ip: str) -> AsyncIterator[AsyncClient]:
        transport = ASGITransport(app=app, client=(ip, 1234))
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            yield ac

    return _open


@pytest.fixture
def mock_provider(monkeypatch):
    fake = AsyncMock()
    fake.available = True
    fake.generate = AsyncMock(
        return_value=LLMResult(content="ok", model="m", tokens_in=1, tokens_out=1)
    )
    from app.routes import comments as comments_route

    monkeypatch.setattr(comments_route, "get_llm_provider", lambda: fake)
    return fake


async def test_zapzap_rate_limited_per_ip(client_from, monkeypatch, mock_provider):
    monkeypatch.setattr(get_settings(), "ip_rl_per_minute", 2)

    async with client_from("1.2.3.4") as c:
        for _ in range(2):
            r = await c.post("/comments/zapzap-analysis", json=_payload())
            assert r.status_code == 200, r.text

        blocked = await c.post("/comments/zapzap-analysis", json=_payload())
        assert blocked.status_code == 429
        assert blocked.headers.get("Retry-After")

    # A different client IP has its own bucket and is unaffected.
    async with client_from("9.9.9.9") as other:
        r = await other.post("/comments/zapzap-analysis", json=_payload())
        assert r.status_code == 200, r.text


async def test_forwarded_for_header_does_not_open_a_new_bucket(
    client_from, monkeypatch, mock_provider
):
    """The 2026-09-13 PoC, inverted: rotating X-Forwarded-For used to mint a bucket per call.

    Nothing reads the header any more — not the app, not uvicorn — so a client writing it
    itself stays in its own bucket.
    """
    from app.services import ip_rate_limiter

    monkeypatch.setattr(get_settings(), "group_rl_per_minute", 3)

    async with client_from("203.0.113.9") as c:
        codes = [
            (
                await c.post(
                    "/groups",
                    json={"name": "g", "device_label": "d"},
                    headers={"X-Forwarded-For": f"10.0.0.{i}"},
                )
            ).status_code
            for i in range(6)
        ]

    assert codes == [201, 201, 201, 429, 429, 429]
    assert list(ip_rate_limiter._buckets) == [("groups", "203.0.113.9")]


GATEWAY = "172.28.87.1"  # the peer Web Station arrives from, docker-compose.prod.yml


@pytest.fixture
def behind_proxy(client):
    """A client that arrives the way Web Station does: from the trusted gateway.

    Wraps the ``client`` fixture's app in the middleware exactly as ``create_app`` does
    with ``TRUSTED_PROXY_IPS`` set, so the test database is shared.
    """
    from app.services.trusted_proxy import TrustedProxyMiddleware

    app = TrustedProxyMiddleware(client._transport.app, trusted_ips=[GATEWAY])

    @asynccontextmanager
    async def _open(peer: str = GATEWAY) -> AsyncIterator[AsyncClient]:
        transport = ASGITransport(app=app, client=(peer, 50000))
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            yield ac

    return _open


async def _join_codes(c: AsyncClient, headers: list[dict]) -> list[int]:
    bogus = {"share_token": "00000000-0000-0000-0000-000000000000", "device_label": "d"}
    return [(await c.post("/groups/join", json=bogus, headers=h)).status_code for h in headers]


async def test_behind_the_proxy_buckets_follow_x_real_ip_not_x_forwarded_for(behind_proxy):
    """The 2026-09-13 production check, which the FORWARDED_ALLOW_IPS fix failed.

    Web Station sets X-Real-IP and passes X-Forwarded-For through as the client wrote it,
    so a rotating X-Forwarded-For must not open a new bucket, and X-Real-IP must.
    """
    from app.services import ip_rate_limiter

    async with behind_proxy() as c:
        spoofing = [
            {"X-Real-IP": "203.0.113.9", "X-Forwarded-For": f"10.9.9.{i}"} for i in range(4)
        ]
        assert await _join_codes(c, spoofing) == [404, 404, 404, 429]
        assert await _join_codes(c, [{"X-Real-IP": "198.51.100.7"}]) == [404]

    assert set(ip_rate_limiter._buckets) == {("groups", "203.0.113.9"), ("groups", "198.51.100.7")}


async def test_x_real_ip_from_an_untrusted_peer_is_ignored(behind_proxy):
    """Reaching the port without the proxy must not let a caller name its own address."""
    from app.services import ip_rate_limiter

    async with behind_proxy(peer="192.0.2.50") as c:
        codes = await _join_codes(c, [{"X-Real-IP": f"10.0.0.{i}"} for i in range(4)])

    assert codes == [404, 404, 404, 429]
    assert list(ip_rate_limiter._buckets) == [("groups", "192.0.2.50")]


@pytest.mark.parametrize("value", ["", "not-an-ip", "1.2.3.4, 5.6.7.8"])
async def test_a_malformed_x_real_ip_keeps_the_proxy_address(value):
    from app.services.trusted_proxy import TrustedProxyMiddleware

    seen: dict = {}

    async def app(scope, receive, send):
        seen.update(client=scope["client"], scheme=scope["scheme"])

    middleware = TrustedProxyMiddleware(app, trusted_ips=[GATEWAY])
    scope = {
        "type": "http",
        "scheme": "http",
        "client": (GATEWAY, 50000),
        "headers": [(b"x-real-ip", value.encode()), (b"x-forwarded-proto", b"https")],
    }
    await middleware(scope, None, None)  # type: ignore[arg-type]

    assert seen == {"client": (GATEWAY, 50000), "scheme": "https"}


async def test_forwarded_proto_sets_the_websocket_scheme():
    from app.services.trusted_proxy import TrustedProxyMiddleware

    seen: dict = {}

    async def app(scope, receive, send):
        seen.update(client=scope["client"], scheme=scope["scheme"])

    middleware = TrustedProxyMiddleware(app, trusted_ips=[GATEWAY])
    scope = {
        "type": "websocket",
        "scheme": "ws",
        "client": (GATEWAY, 50000),
        "headers": [(b"x-real-ip", b"2001:db8::1"), (b"x-forwarded-proto", b"https")],
    }
    await middleware(scope, None, None)  # type: ignore[arg-type]

    assert seen == {"client": ("2001:db8::1", 50000), "scheme": "wss"}


def test_create_app_runs_the_trusted_proxy_middleware_first(monkeypatch):
    """Outermost, so the rate limits — and every other middleware — see the real client."""
    from app.main import create_app
    from app.services.trusted_proxy import TrustedProxyMiddleware

    monkeypatch.setattr(get_settings(), "trusted_proxy_ips", f" {GATEWAY} , 10.0.0.1")
    app = create_app()

    first = app.user_middleware[0]
    assert first.cls is TrustedProxyMiddleware
    assert first.kwargs == {"trusted_ips": [GATEWAY, "10.0.0.1"]}


async def test_mvp_rate_limited_per_ip(client_from, monkeypatch):
    from app.services.anthropic_client import CommentResult

    fake = AsyncMock()
    fake.available = True
    fake.generate_comment = AsyncMock(
        return_value=CommentResult(
            content="x", model="claude-haiku-4-5", tokens_in=1, tokens_out=1, cost_cents=1
        )
    )
    from app.routes import comments as comments_route

    monkeypatch.setattr(comments_route, "get_anthropic_client", lambda: fake)
    monkeypatch.setattr(get_settings(), "ip_rl_per_minute", 1)

    payload = {
        "game_name": "g",
        "game_type": "g",
        "is_lowest_score_wins": True,
        "players": [{"uuid": "p", "name": "Alice"}],
        "rounds": [{"n": 1, "scores": [{"player_uuid": "p", "value": 1}]}],
    }
    async with client_from("2.2.2.2") as c:
        r1 = await c.post("/comments/mvp", json=payload)
        assert r1.status_code == 200, r1.text
        r2 = await c.post("/comments/mvp", json=payload)
        assert r2.status_code == 429


async def test_body_too_large_returns_413(client):
    oversized = {"game": {"name": "a" * 300_000}}
    r = await client.post("/comments/zapzap-analysis", json=oversized)
    assert r.status_code == 413


def test_buckets_do_not_share_counters():
    """Group spam must not consume the quota that guards the paid LLM calls."""
    from app.config import get_settings
    from app.services.ip_rate_limiter import check_ip_rate_limit

    settings = get_settings()
    for _ in range(settings.group_rl_per_minute):
        assert check_ip_rate_limit(
            "1.2.3.4",
            bucket="groups",
            per_minute=settings.group_rl_per_minute,
            per_hour=settings.group_rl_per_hour,
        ).allowed
    assert not check_ip_rate_limit(
        "1.2.3.4",
        bucket="groups",
        per_minute=settings.group_rl_per_minute,
        per_hour=settings.group_rl_per_hour,
    ).allowed

    assert check_ip_rate_limit("1.2.3.4").allowed


def test_different_ips_do_not_share_counters():
    from app.config import get_settings
    from app.services.ip_rate_limiter import check_ip_rate_limit

    for _ in range(get_settings().ip_rl_per_minute):
        assert check_ip_rate_limit("10.0.0.1").allowed

    assert not check_ip_rate_limit("10.0.0.1").allowed
    assert check_ip_rate_limit("10.0.0.2").allowed
