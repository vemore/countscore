"""The derived facts.

These exist because the model is forbidden to quote the numbers but required to judge
them, so it does arithmetic it can never check. Everything asserted here is what it would
otherwise have had to count itself.
"""

from __future__ import annotations

import pytest

from app.services.analysis.game_rules import GameRules
from app.services.analysis.signals import compute_signals, render_signals

LOW = GameRules(is_lowest_score_wins=True)
HIGH = GameRules(is_lowest_score_wins=False)


def _game(players: list[str], rounds: list[list[int | None]], history=None) -> dict:
    return {
        "players": [{"id": i, "name": n} for i, n in enumerate(players, start=1)],
        "rounds": [
            {
                "number": n,
                "comment": None,
                "scores": [{"player_id": i, "value": v} for i, v in enumerate(values, start=1)],
            }
            for n, values in enumerate(rounds, start=1)
        ],
        "history_by_player_name": history or {},
    }


def _by_name(signals):
    return {p.name: p for p in signals.players}


def test_totals_and_rank_follow_the_scoring_direction():
    game = _game(["A", "B"], [[10, 1], [10, 1]])
    low = _by_name(compute_signals(game, LOW))
    assert (low["A"].total, low["A"].rank) == (20, 2)
    assert (low["B"].total, low["B"].rank) == (2, 1)

    high = _by_name(compute_signals(game, HIGH))
    assert high["A"].rank == 1
    assert high["B"].rank == 2


def test_a_tie_is_a_shared_rank_and_names_the_other_player():
    signals = compute_signals(_game(["A", "B", "C"], [[5, 5, 9]]), LOW)
    by_name = _by_name(signals)
    assert by_name["A"].rank == by_name["B"].rank == 1
    assert by_name["A"].tied_with == ["B"]
    assert by_name["C"].rank == 2  # dense rank: no gap after a tie


def test_a_missing_score_is_a_round_the_player_sat_out():
    """A None value adds nothing, exactly as the old cumulative table did."""
    signals = compute_signals(_game(["A", "B"], [[5, None], [5, 3]]), LOW)
    by_name = _by_name(signals)
    assert by_name["B"].total == 3
    assert by_name["B"].rounds_played == 1
    assert "sat out 1 rounds" in render_signals(signals)


def test_lead_changes_and_the_round_the_game_turned():
    # A leads after round 1, B takes it in round 2 and keeps it.
    signals = compute_signals(_game(["A", "B"], [[1, 9], [20, 1], [1, 1]]), LOW)
    assert signals.lead_changes == 1
    assert signals.decided_at_round == 2
    by_name = _by_name(signals)
    assert by_name["A"].rounds_in_lead == 1
    assert by_name["B"].rounds_in_lead == 2


def test_a_comeback_and_a_collapse_are_named():
    # C is last after the first round and wins; A leads and finishes last.
    signals = compute_signals(_game(["A", "B", "C"], [[0, 5, 30], [50, 40, 0]]), LOW)
    by_name = _by_name(signals)
    assert by_name["C"].trajectory == "comeback"
    assert by_name["A"].trajectory == "collapse"
    assert by_name["B"].trajectory == "flat"


def test_consistency_buckets_a_players_rounds():
    steady = _by_name(compute_signals(_game(["A"], [[10], [10], [11]]), LOW))["A"]
    erratic = _by_name(compute_signals(_game(["A"], [[0], [0], [60]]), LOW))["A"]
    assert steady.consistency == "steady"
    assert erratic.consistency == "erratic"
    # One round is not a spread.
    assert _by_name(compute_signals(_game(["A"], [[42]]), LOW))["A"].consistency == "steady"


def test_best_and_worst_round_follow_the_direction_too():
    low = _by_name(compute_signals(_game(["A"], [[30], [2], [10]]), LOW))["A"]
    assert low.best_round == (2, 2)
    assert low.worst_round == (1, 30)
    high = _by_name(compute_signals(_game(["A"], [[30], [2], [10]]), HIGH))["A"]
    assert high.best_round == (1, 30)
    assert high.worst_round == (2, 2)


@pytest.mark.parametrize(
    ("condition", "threshold", "expected"),
    [
        ("over", 100, 3),
        ("under", -10, None),
        (None, None, None),
    ],
)
def test_elimination_is_read_off_the_running_total(condition, threshold, expected):
    rules = GameRules(
        is_lowest_score_wins=True,
        player_dead_condition_type=condition,
        player_dead_threshold=threshold,
    )
    signals = compute_signals(_game(["A"], [[50], [40], [30]]), rules)
    assert _by_name(signals)["A"].eliminated_at_round == expected


def test_elimination_under_a_floor():
    rules = GameRules(
        is_lowest_score_wins=False,
        player_dead_condition_type="under",
        player_dead_threshold=0,
    )
    signals = compute_signals(_game(["A"], [[5], [-10]]), rules)
    assert _by_name(signals)["A"].eliminated_at_round == 2


def test_a_players_standing_is_compared_with_their_usual_one():
    """Ranks are compared on a 0..1 scale: 3rd of 4 and 3rd of 12 are not the same night."""
    history = {
        "A": [{"rank": 1, "totalPlayers": 4, "didWin": True} for _ in range(4)],
        "B": [{"rank": 4, "totalPlayers": 4, "didWin": False} for _ in range(4)],
    }
    # A finishes last tonight, B wins.
    signals = compute_signals(_game(["A", "B"], [[50, 1]], history), LOW)
    by_name = _by_name(signals)
    assert by_name["A"].rank_vs_history == "below their usual"
    assert by_name["A"].history_win_rate == 1.0
    assert by_name["B"].rank_vs_history == "above their usual"
    assert by_name["B"].history_games == 4


def test_form_over_the_recorded_games_is_read_chronologically():
    """The repository returns the most recent game first — improving means recently better."""
    recent_first = [
        {"rank": 1, "totalPlayers": 5},
        {"rank": 1, "totalPlayers": 5},
        {"rank": 5, "totalPlayers": 5},
        {"rank": 5, "totalPlayers": 5},
    ]
    signals = compute_signals(_game(["A"], [[1]], {"A": recent_first}), LOW)
    assert _by_name(signals)["A"].history_trend == "improving"

    signals = compute_signals(_game(["A"], [[1]], {"A": list(reversed(recent_first))}), LOW)
    assert _by_name(signals)["A"].history_trend == "declining"


def test_too_few_recorded_games_is_no_trend_at_all():
    signals = compute_signals(_game(["A"], [[1]], {"A": [{"rank": 1, "totalPlayers": 3}]}), LOW)
    player = _by_name(signals)["A"]
    assert player.history_trend is None
    assert player.history_games == 1


def test_tightness_compares_the_margin_with_a_typical_round():
    photo = compute_signals(_game(["A", "B"], [[20, 21], [20, 20]]), LOW)
    blowout = compute_signals(_game(["A", "B"], [[1, 60], [1, 60]]), LOW)
    assert photo.tightness == "photo finish"
    assert photo.margin_first_to_second == 1
    assert blowout.tightness == "blowout"


def test_a_game_with_no_round_says_so_and_counts_nothing():
    signals = compute_signals(_game(["A", "B"], []), LOW)
    assert signals.rounds_count == 0
    assert signals.lead_changes == 0
    assert signals.decided_at_round is None
    assert all(p.trajectory == "flat" for p in signals.players)
    assert "No round was played" in render_signals(signals)


def test_a_single_player_is_not_a_division_by_zero():
    signals = compute_signals(_game(["A"], [[5]], {"A": [{"rank": 1, "totalPlayers": 1}]}), LOW)
    player = _by_name(signals)["A"]
    assert player.rank == 1
    assert player.rank_vs_history == "in line with their usual"


def test_the_rendered_block_leads_with_the_labels_not_the_arithmetic():
    history = {"A": [{"rank": 3, "totalPlayers": 3, "didWin": False} for _ in range(4)]}
    text = render_signals(compute_signals(_game(["A", "B"], [[1, 9], [1, 30]], history), LOW))
    assert text.startswith("## Derived facts (for your judgement — never quote them back)")
    assert "Finish: " in text
    assert "trajectory: " in text
    assert "above their usual" in text
    assert "wins about 0% of the time" in text


def test_rounds_are_read_in_order_whatever_order_they_arrive_in():
    game = _game(["A", "B"], [[1, 9], [30, 1]])
    game["rounds"].reverse()
    signals = compute_signals(game, LOW)
    assert signals.decided_at_round == 2
    assert _by_name(signals)["A"].best_round == (1, 1)
