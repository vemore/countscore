"""The rules section: the registry, the generic fallback, and what overrides what."""

from __future__ import annotations

import pytest

from app.services.analysis.game_rules import (
    KNOWN_GAME_TYPES,
    GameRules,
    describe_rules,
    normalise_game_over_condition,
    normalise_game_type,
    normalise_player_dead_condition,
)

GENERIC = "You do not know the rules of this game"


@pytest.mark.parametrize(
    ("name", "key"),
    [
        ("ZapZap", "zapzap"),
        ("zapzap", "zapzap"),
        ("Président", "president"),
        ("PRESIDENT", "president"),
        ("  president  ", "president"),
        ("Rami", "rami"),
        ("6 qui prend", "6quiprend"),
        (None, ""),
        (42, ""),
    ],
)
def test_game_type_names_fold_to_a_registry_key(name, key):
    assert normalise_game_type(name) == key


@pytest.mark.parametrize("key", sorted(KNOWN_GAME_TYPES))
def test_every_seeded_type_with_a_scoring_shape_has_a_block(key):
    block = describe_rules(key, GameRules(is_lowest_score_wins=True))
    assert KNOWN_GAME_TYPES[key] in block
    assert GENERIC not in block


@pytest.mark.parametrize("name", ["Autre", "Mölkky", "Yahtzee", "", None, "Le jeu de Tata Jeanne"])
def test_an_unknown_or_custom_type_gets_the_generic_block_and_invents_nothing(name):
    """A user can create any game type, so most names in the wild are not in the registry."""
    block = describe_rules(name, GameRules(is_lowest_score_wins=False))
    assert GENERIC in block
    assert "Do not invent any" in block
    assert "Points are gains: the highest total wins." in block


@pytest.mark.parametrize("lowest", [True, False])
@pytest.mark.parametrize(
    ("dead", "threshold", "expected"),
    [
        (None, None, None),
        ("over", 100, "goes above 100"),
        ("under", -50, "falls below -50"),
        ("over", None, None),  # a condition with no threshold is not a condition
        ("sideways", 100, None),
    ],
)
@pytest.mark.parametrize(
    ("over", "over_threshold", "expected_over"),
    [
        (None, None, None),
        ("firstPlayerOver", 500, "as soon as one player's total reaches 500"),
        ("firstPlayerUnder", 0, "as soon as one player's total falls below 0"),
        ("lastPlayerOver", 11, "once every player's total has gone above 11"),
        ("lastPlayerUnder", 3, "once every player's total has fallen below 3"),
    ],
)
def test_the_configuration_renders_from_the_structured_fields(
    lowest, dead, threshold, expected, over, over_threshold, expected_over
):
    block = describe_rules(
        "Mölkky",
        GameRules(
            is_lowest_score_wins=lowest,
            player_dead_condition_type=normalise_player_dead_condition(dead),
            player_dead_threshold=threshold,
            game_over_condition_type=normalise_game_over_condition(over),
            game_over_threshold=over_threshold,
        ),
    )
    direction = "lowest" if lowest else "highest"
    assert f"{direction} total wins" in block
    if expected is None:
        assert "is eliminated as soon as" not in block
    else:
        assert expected in block
    if expected_over is None:
        assert "The game ends" not in block
    else:
        assert expected_over in block


def test_the_payload_configuration_overrides_the_registry_block():
    """A user may rename or retune a seeded type; the payload is the ground truth."""
    block = describe_rules(
        "ZapZap",
        GameRules(
            is_lowest_score_wins=False, player_dead_condition_type="over", player_dead_threshold=250
        ),
    )
    assert KNOWN_GAME_TYPES["zapzap"] in block
    assert "they override anything above" in block
    assert "Points are gains: the highest total wins." in block
    assert "goes above 250" in block


@pytest.mark.parametrize(
    ("value", "expected"),
    [("over", "over"), ("OVER", "over"), ("under", "under"), ("", None), (None, None), (7, None)],
)
def test_unknown_conditions_mean_absent_rather_than_invalid(value, expected):
    assert normalise_player_dead_condition(value) == expected


@pytest.mark.parametrize(
    ("value", "expected"),
    [
        ("firstPlayerOver", "firstPlayerOver"),
        ("firstplayerover", "firstPlayerOver"),
        ("lastPlayerUnder", "lastPlayerUnder"),
        ("nope", None),
    ],
)
def test_game_over_conditions_normalise_case_insensitively(value, expected):
    assert normalise_game_over_condition(value) == expected
