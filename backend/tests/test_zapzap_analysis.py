"""Tests for POST /comments/zapzap-analysis and the ZapZap prompt builder.

The LLM provider is mocked — we exercise routing, validation, error mapping and
the Markdown prompt construction, not the LLM itself.
"""
from __future__ import annotations

from unittest.mock import AsyncMock

import pytest

from app.services.llm import LLMResult
from app.services.zapzap_prompt import build_zapzap_user_message


def _payload() -> dict:
    return {
        "game": {
            "id": 42,
            "name": "Soirée ZapZap",
            "is_lowest_score_wins": True,
            "created_at": "2026-05-01T20:30:00.000",
        },
        "game_type": "ZapZap",
        "players": [
            {"id": 1, "name": "Nadia"},
            {"id": 2, "name": "Vincent"},
        ],
        "rounds": [
            {
                "id": 10,
                "number": 1,
                "comment": "manche tranquille",
                "scores": [
                    {"player_id": 1, "value": 0},
                    {"player_id": 2, "value": 18},
                ],
            },
            {
                "id": 11,
                "number": 2,
                "comment": None,
                "scores": [
                    {"player_id": 1, "value": 5},
                    {"player_id": 2, "value": 12},
                ],
            },
        ],
        "history_by_player_name": {
            "Nadia": [
                {
                    "gameName": "p160",
                    "gameType": "ZapZap",
                    "date": "2026-04-20T21:00:00.000",
                    "finalScore": 88,
                    "totalPlayers": 5,
                    "rank": 1,
                    "didWin": True,
                }
            ],
            "Vincent": [],
        },
    }


@pytest.fixture
def mock_provider(monkeypatch):
    fake = AsyncMock()
    fake.available = True
    fake.generate = AsyncMock(
        return_value=LLMResult(
            content="## Verdict\nNadia, intouchable comme toujours.",
            model="us.meta.llama3-3-70b-instruct-v1:0",
            tokens_in=512,
            tokens_out=300,
        )
    )
    from app.routes import comments as comments_route
    monkeypatch.setattr(comments_route, "get_llm_provider", lambda: fake)
    return fake


async def test_zapzap_success(client, mock_provider):
    r = await client.post("/comments/zapzap-analysis", json=_payload())
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["content"].startswith("## Verdict")
    assert body["model"] == "us.meta.llama3-3-70b-instruct-v1:0"
    assert body["tokens_in"] == 512
    assert body["tokens_out"] == 300
    assert mock_provider.generate.call_count == 1

    # generate(system_prompt, user_message): the user message (arg 1) carries the game data.
    system_prompt, user_message = mock_provider.generate.call_args.args
    assert "professeur Claude" in system_prompt
    assert "Soirée ZapZap" in user_message
    assert "| Manche |" in user_message


async def test_zapzap_missing_config_returns_503(client, monkeypatch):
    stub = AsyncMock()
    stub.available = False
    from app.routes import comments as comments_route
    monkeypatch.setattr(comments_route, "get_llm_provider", lambda: stub)

    r = await client.post("/comments/zapzap-analysis", json=_payload())
    assert r.status_code == 503


async def test_zapzap_invalid_payload_returns_422(client, mock_provider):
    # Missing the required "game" key.
    r = await client.post("/comments/zapzap-analysis", json={"players": []})
    assert r.status_code == 422
    assert mock_provider.generate.call_count == 0


async def test_zapzap_upstream_error_returns_502(client, monkeypatch):
    fake = AsyncMock()
    fake.available = True
    fake.generate = AsyncMock(side_effect=RuntimeError("provider down"))
    from app.routes import comments as comments_route
    monkeypatch.setattr(comments_route, "get_llm_provider", lambda: fake)

    r = await client.post("/comments/zapzap-analysis", json=_payload())
    assert r.status_code == 502


# --- Prompt builder unit tests -------------------------------------------------


def test_builder_renders_score_table_with_cumulative_totals():
    msg = build_zapzap_user_message(_payload())
    # Header row lists both players in order.
    assert "| Manche | Nadia | Vincent | Commentaire |" in msg
    # Round 1: Nadia 0 (cumul 0), Vincent 18 (cumul 18); comment carried over.
    assert "| 1 | 0 (0) | 18 (18) | manche tranquille |" in msg
    # Round 2 accumulates: Nadia 5 (cumul 5), Vincent 12 (cumul 30); empty comment.
    assert "| 2 | 5 (5) | 12 (30) |  |" in msg


def test_builder_renders_final_totals():
    msg = build_zapzap_user_message(_payload())
    assert "- Nadia : 5 pts" in msg
    assert "- Vincent : 30 pts" in msg


def test_builder_renders_history_with_rank_and_trophy():
    msg = build_zapzap_user_message(_payload())
    assert "### Nadia" in msg
    assert "🏆" in msg
    assert "rang 1/5" in msg
    assert "score 88" in msg
    # Vincent has no history.
    assert "Aucun historique disponible." in msg


def test_builder_handles_missing_round_score():
    payload = _payload()
    payload["rounds"][0]["scores"] = [{"player_id": 1, "value": 0}]  # Vincent missing
    msg = build_zapzap_user_message(payload)
    assert "| 1 | 0 (0) | — | manche tranquille |" in msg


def test_builder_handles_no_rounds():
    payload = _payload()
    payload["rounds"] = []
    msg = build_zapzap_user_message(payload)
    assert "Aucune manche enregistrée." in msg
