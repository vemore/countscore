"""Tests for /comments endpoints.

Anthropic API calls are mocked. The point is to exercise routing, validation,
rate-limiting and budget logic — not to verify Claude itself.
"""
from __future__ import annotations

from unittest.mock import AsyncMock

import pytest

from app.services.anthropic_client import CommentResult


@pytest.fixture
def mock_anthropic(monkeypatch):
    """Patch get_anthropic_client so the endpoint does not hit the real API."""
    fake = AsyncMock()
    fake.available = True
    fake.generate_comment = AsyncMock(
        return_value=CommentResult(
            content="Alice a dominé.",
            model="claude-haiku-4-5",
            tokens_in=200,
            tokens_out=50,
            cost_cents=1,
        )
    )
    from app.routes import comments as comments_route
    monkeypatch.setattr(comments_route, "get_anthropic_client", lambda: fake)
    return fake


async def test_mvp_endpoint(client, mock_anthropic):
    payload = {
        "game_name": "Skyjo soirée",
        "game_type": "Skyjo",
        "is_lowest_score_wins": True,
        "players": [
            {"uuid": "p1", "name": "Alice"},
            {"uuid": "p2", "name": "Bob"},
        ],
        "rounds": [
            {
                "n": 1,
                "scores": [
                    {"player_uuid": "p1", "value": 5},
                    {"player_uuid": "p2", "value": 10},
                ],
            },
        ],
        "style": "narrative",
        "language": "fr",
    }
    r = await client.post("/comments/mvp", json=payload)
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["content"] == "Alice a dominé."
    assert body["model"] == "claude-haiku-4-5"
    assert mock_anthropic.generate_comment.call_count == 1


async def test_mvp_validates_player_names(client, mock_anthropic):
    """Names are bounded by Pydantic constraints (length 1-32)."""
    payload = {
        "game_name": "Test",
        "game_type": "Test",
        "is_lowest_score_wins": True,
        "players": [{"uuid": "p1", "name": "x" * 33}],  # too long
        "rounds": [{"n": 1, "scores": [{"player_uuid": "p1", "value": 1}]}],
    }
    r = await client.post("/comments/mvp", json=payload)
    assert r.status_code == 422


async def test_mvp_requires_anthropic_key(client, monkeypatch):
    """If ANTHROPIC_API_KEY missing, endpoint returns 503."""
    from app.services.anthropic_client import AnthropicClient
    stub = AnthropicClient.__new__(AnthropicClient)
    stub._client = None
    stub.model = "claude-haiku-4-5"
    from app.routes import comments as comments_route
    monkeypatch.setattr(comments_route, "get_anthropic_client", lambda: stub)

    payload = {
        "game_name": "g",
        "game_type": "g",
        "is_lowest_score_wins": True,
        "players": [{"uuid": "p", "name": "Alice"}],
        "rounds": [{"n": 1, "scores": [{"player_uuid": "p", "value": 1}]}],
    }
    r = await client.post("/comments/mvp", json=payload)
    assert r.status_code == 503
