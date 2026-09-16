"""The composed system prompt: nine voices, ten languages, one editorial contract.

Every case here is pure string building — no HTTP, no LLM — so the whole nine-by-ten matrix
costs milliseconds.
"""

from __future__ import annotations

import re

import pytest

from app.services.analysis import (
    DEFAULT_PERSONA,
    LANGUAGES,
    PERSONA_KEYS,
    PERSONAS,
    build_system_prompt,
    resolve_language,
    resolve_persona,
)

# A short phrase unique to each voice, so a leak from one persona into another is visible.
SIGNATURES = {
    "professor": "le professeur Claude",
    "commentator": "live sports commentator",
    "documentary": "wildlife documentary",
    "noir": "private detective",
    "bard": "You are a bard",
    "coach": "warm, attentive coach",
    "consultant": "management consultant",
    "astrologer": "You are an astrologer",
    "reality_tv": "reality competition show",
}


def _payload(**overrides) -> dict:
    base = {
        "game": {
            "name": "Soirée",
            "is_lowest_score_wins": True,
            "created_at": "2026-05-01T20:30:00.000",
        },
        "game_type": "ZapZap",
        "players": [{"id": 1, "name": "A"}],
        "rounds": [],
    }
    return base | overrides


ALL_PROMPTS = {
    (persona, code): build_system_prompt(_payload(style=persona, language=code))
    for persona in PERSONA_KEYS
    for code in LANGUAGES
}


def test_the_matrix_is_the_nine_voices_by_the_ten_languages():
    assert len(PERSONAS) == 9
    assert len(LANGUAGES) == 10
    assert len(ALL_PROMPTS) == 90


@pytest.mark.parametrize("persona", PERSONA_KEYS)
def test_exactly_one_voice_reaches_the_prompt(persona):
    prompt = ALL_PROMPTS[(persona, "fr")]
    assert SIGNATURES[persona] in prompt
    for other, signature in SIGNATURES.items():
        if other != persona:
            assert signature not in prompt


@pytest.mark.parametrize("code", sorted(LANGUAGES))
def test_the_language_directive_is_sandwiched(code):
    """Emitted twice on purpose — see languages.py; it is what holds ar/hi/ja/zh in line."""
    prompt = ALL_PROMPTS[("professor", code)]
    assert prompt.count(LANGUAGES[code].directive) == 2
    assert prompt.rstrip().endswith(LANGUAGES[code].directive)


@pytest.mark.parametrize(
    ("tag", "expected"),
    [
        ("fr", "fr"),
        ("FR", "fr"),
        ("fr_FR", "fr"),
        ("pt-BR", "pt"),
        ("zh-Hant-TW", "zh"),
        ("  en  ", "en"),
        ("kl", "en"),
        ("", "en"),
        ("klingon", "en"),
        (None, "en"),
        (42, "en"),
    ],
)
def test_locale_tags_resolve_to_a_supported_language(tag, expected):
    assert resolve_language(tag).code == expected


@pytest.mark.parametrize(
    ("value", "expected"),
    [
        ("bard", "bard"),
        ("BARD", "bard"),
        (" coach ", "coach"),
        ("reality_tv", "reality_tv"),
        ("reality-tv", DEFAULT_PERSONA),
        ("", DEFAULT_PERSONA),
        (None, DEFAULT_PERSONA),
        (["bard"], DEFAULT_PERSONA),
    ],
)
def test_an_unknown_style_falls_back_rather_than_failing(value, expected):
    assert resolve_persona(value) == expected


@pytest.mark.parametrize("persona", PERSONA_KEYS)
@pytest.mark.parametrize("code", ["fr", "ja", "ar"])
def test_every_prompt_carries_the_editorial_contract(persona, code):
    """The point of the change: one page, about how they played, not about the numbers."""
    prompt = ALL_PROMPTS[(persona, code)]
    assert "250 to 350 words" in prompt
    assert "No tables. Ever." in prompt
    assert "already displays every number on its other screens" in prompt
    assert "Never comment on a person's appearance" in prompt
    assert "<player_name>" in prompt and "<game_type>" in prompt
    # Gemini copied the tags straight into its answer before this line existed.
    assert "never reproduce a tag in it" in prompt


def test_only_the_professor_may_grade():
    assert "mark out of 20" in ALL_PROMPTS[("professor", "fr")]
    for persona in PERSONA_KEYS:
        if persona != "professor":
            assert "out of 20" not in PERSONAS[persona]


# A prompt constant reaches the provider on every single request, whoever is playing and
# whoever runs the backend. Real people belong in the payload, which the user chose to
# send. The first eight names are the regulars the original ZapZap prompt used to carry
# and describe (removed 2026-09-13, .llmwiki/Security.md); the rest are the figures one is
# tempted to reach for when writing a commentator, a detective or an astrologer "in the
# style of" someone.
FORBIDDEN_NAMES = [
    "Thibaut",
    "Vincent",
    "Lionel",
    "Laurent",
    "Guillaume",
    "Simon",
    "Nadia",
    "Ben",
    "Attenborough",
    "Sherlock",
    "Holmes",
    "Marlowe",
    "Poirot",
    "Columbo",
    "Nostradamus",
    "Homer",
    "Oprah",
]


@pytest.mark.parametrize("name", FORBIDDEN_NAMES)
def test_no_prompt_names_a_real_person(name):
    for (persona, code), prompt in ALL_PROMPTS.items():
        assert re.search(rf"\b{name}\b", prompt) is None, f"{name} in {persona}/{code}"
        assert "chouchou" not in prompt
