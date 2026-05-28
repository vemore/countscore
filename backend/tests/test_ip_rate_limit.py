"""Tests for the per-IP throttle on the public LLM endpoints and the body-size cap."""
from __future__ import annotations

from unittest.mock import AsyncMock

import pytest

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
def mock_provider(monkeypatch):
    fake = AsyncMock()
    fake.available = True
    fake.generate = AsyncMock(
        return_value=LLMResult(content="ok", model="m", tokens_in=1, tokens_out=1)
    )
    from app.routes import comments as comments_route
    monkeypatch.setattr(comments_route, "get_llm_provider", lambda: fake)
    return fake


async def test_zapzap_rate_limited_per_ip(client, monkeypatch, mock_provider):
    monkeypatch.setattr(get_settings(), "ip_rl_per_minute", 2)
    headers = {"X-Forwarded-For": "1.2.3.4"}

    for _ in range(2):
        r = await client.post("/comments/zapzap-analysis", json=_payload(), headers=headers)
        assert r.status_code == 200, r.text

    blocked = await client.post("/comments/zapzap-analysis", json=_payload(), headers=headers)
    assert blocked.status_code == 429
    assert blocked.headers.get("Retry-After")

    # A different client IP has its own bucket and is unaffected.
    other = await client.post(
        "/comments/zapzap-analysis", json=_payload(), headers={"X-Forwarded-For": "9.9.9.9"}
    )
    assert other.status_code == 200, other.text


async def test_mvp_rate_limited_per_ip(client, monkeypatch):
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
    headers = {"X-Forwarded-For": "2.2.2.2"}
    r1 = await client.post("/comments/mvp", json=payload, headers=headers)
    assert r1.status_code == 200, r1.text
    r2 = await client.post("/comments/mvp", json=payload, headers=headers)
    assert r2.status_code == 429


async def test_body_too_large_returns_413(client):
    oversized = {"game": {"name": "a" * 300_000}}
    r = await client.post("/comments/zapzap-analysis", json=oversized)
    assert r.status_code == 413
