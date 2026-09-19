"""POST /groups/me/games/{game_id}/comments with an ``analysis`` body.

The analysis of a shared game: the game-analysis prompt, billed to the group, in the
group's language, and in the group's style when the device picked no voice. The LLM
provider is mocked, as in test_game_analysis.py.
"""

from __future__ import annotations

import uuid
from unittest.mock import AsyncMock

import pytest

from app.models import Game
from app.services.analysis import GROUP_STYLE_PERSONAS, PERSONAS, persona_for_group_style
from app.services.llm import LLMRateLimitedError, LLMResult
from tests.test_game_analysis import _payload


@pytest.fixture
def mock_provider(monkeypatch):
    fake = AsyncMock()
    fake.available = True
    fake.generate = AsyncMock(
        return_value=LLMResult(
            content="## Verdict\nNadia gagne.",
            model="gemini-2.5-flash",
            tokens_in=2_000,
            tokens_out=800,
        )
    )
    from app.routes import comments as comments_route

    monkeypatch.setattr(comments_route, "get_llm_provider", lambda: fake)
    return fake


async def _group(client) -> tuple[str, dict[str, str]]:
    r = await client.post("/groups", json={"name": "g", "device_label": "d"})
    body = r.json()
    return body["group"]["id"], {"Authorization": f"Bearer {body['device']['token']}"}


async def _shared_game(session_factory, group_id: str) -> uuid.UUID:
    game = Game(group_id=uuid.UUID(group_id), name="Soirée ZapZap")
    async with session_factory() as s:
        s.add(game)
        await s.commit()
    return game.id


def _analysis(**overrides) -> dict:
    payload = _payload()
    payload.pop("style", None)
    return payload | overrides


async def _used_cents(client, headers) -> int:
    r = await client.get("/groups/me/usage", headers=headers)
    assert r.status_code == 200, r.text
    return r.json()["current_month_used_cents"]


async def test_shared_game_analysis_is_billed_to_the_group(client, session_factory, mock_provider):
    group_id, headers = await _group(client)
    game_id = await _shared_game(session_factory, group_id)
    assert await _used_cents(client, headers) == 0

    r = await client.post(
        f"/groups/me/games/{game_id}/comments",
        json={"analysis": _analysis(style="bard")},
        headers=headers,
    )

    assert r.status_code == 201, r.text
    body = r.json()
    assert body["content"].startswith("## Verdict")
    assert body["model"] == "gemini-2.5-flash"
    assert body["style"] == "bard"
    assert body["cost_cents"] >= 1
    assert await _used_cents(client, headers) == body["cost_cents"]

    system_prompt, user_message = mock_provider.generate.call_args.args
    assert "You are a bard" in system_prompt  # the voice the device picked wins
    assert "Soirée ZapZap" in user_message

    r = await client.get(f"/groups/me/games/{game_id}/comments", headers=headers)
    assert [c["style"] for c in r.json()] == ["bard"]


async def test_no_voice_picked_uses_the_group_style_and_language(
    client, session_factory, mock_provider
):
    group_id, headers = await _group(client)
    game_id = await _shared_game(session_factory, group_id)
    r = await client.patch(
        "/groups/me/settings",
        json={"comment_style": "analytical", "comment_language": "de"},
        headers=headers,
    )
    assert r.status_code == 200, r.text

    # The device's display language is French; the group's language wins.
    r = await client.post(
        f"/groups/me/games/{game_id}/comments",
        json={"analysis": _analysis(language="fr")},
        headers=headers,
    )

    assert r.status_code == 201, r.text
    assert r.json()["style"] == "coach"
    assert r.json()["language"] == "de"
    system_prompt, _ = mock_provider.generate.call_args.args
    assert "warm, attentive coach" in system_prompt
    assert "Antworte vollständig auf Deutsch." in system_prompt


async def test_a_group_over_its_budget_gets_409_and_no_call(client, session_factory, mock_provider):
    group_id, headers = await _group(client)
    game_id = await _shared_game(session_factory, group_id)
    r = await client.patch("/groups/me/settings", json={"monthly_budget_cents": 0}, headers=headers)
    assert r.status_code == 200, r.text

    r = await client.post(
        f"/groups/me/games/{game_id}/comments",
        json={"analysis": _analysis()},
        headers=headers,
    )

    assert r.status_code == 409, r.text
    assert "budget" in r.json()["detail"]
    assert mock_provider.generate.call_count == 0


async def test_a_game_of_another_group_is_404_and_bills_nothing(
    client, session_factory, mock_provider
):
    other_group_id, _ = await _group(client)
    foreign_game = await _shared_game(session_factory, other_group_id)
    _, headers = await _group(client)

    for game_id in (foreign_game, uuid.uuid4()):
        r = await client.post(
            f"/groups/me/games/{game_id}/comments",
            json={"analysis": _analysis()},
            headers=headers,
        )
        assert r.status_code == 404, r.text

    assert mock_provider.generate.call_count == 0
    assert await _used_cents(client, headers) == 0


async def test_an_upstream_rate_limit_is_503_and_bills_nothing(
    client, session_factory, mock_provider
):
    group_id, headers = await _group(client)
    game_id = await _shared_game(session_factory, group_id)
    mock_provider.generate.side_effect = LLMRateLimitedError("quota")

    r = await client.post(
        f"/groups/me/games/{game_id}/comments",
        json={"analysis": _analysis()},
        headers=headers,
    )

    assert r.status_code == 503
    assert r.headers["Retry-After"] == "60"
    assert await _used_cents(client, headers) == 0


async def test_the_analysis_needs_a_device_token(client, mock_provider):
    r = await client.post(
        f"/groups/me/games/{uuid.uuid4()}/comments", json={"analysis": _analysis()}
    )
    assert r.status_code == 401
    assert mock_provider.generate.call_count == 0


def test_every_group_style_maps_to_a_voice():
    # The three styles PATCH /groups/me/settings accepts.
    assert set(GROUP_STYLE_PERSONAS) == {"narrative", "humorous", "analytical"}
    assert all(persona in PERSONAS for persona in GROUP_STYLE_PERSONAS.values())
    assert persona_for_group_style("no-such-style") == "professor"
    assert persona_for_group_style(None) == "professor"
