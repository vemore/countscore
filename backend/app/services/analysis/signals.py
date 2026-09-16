"""Derived facts about a game, computed in Python rather than by the model.

The editorial contract forbids quoting the numbers back but requires judging them, so
the model has to do arithmetic it is never allowed to show — which means its mistakes are
invisible to it and glaring to the reader ("X led until round 7" when X never led).
Summing twelve columns over two hundred rounds is exactly what these models get wrong.

So the counting happens here, deterministically and under test, and the model receives
qualitative labels — ``erratic``, ``comeback``, ``below their usual`` — which are the very
words the contract asks it to verbalise.
"""

from __future__ import annotations

import statistics
from dataclasses import dataclass, field
from typing import Any

from .game_rules import GameRules

# A player's standing is compared with their usual one on a 0..1 scale (0 = won), because
# a 3rd place out of 4 and a 3rd out of 12 are not the same result.
_RANK_SHIFT_THRESHOLD = 0.15
_TREND_MIN_GAMES = 4


@dataclass(slots=True)
class PlayerSignals:
    name: str
    total: int
    rank: int
    tied_with: list[str] = field(default_factory=list)
    rounds_played: int = 0
    best_round: tuple[int, int] | None = None
    worst_round: tuple[int, int] | None = None
    consistency: str = "steady"
    rounds_in_lead: int = 0
    best_rank_seen: int = 1
    worst_rank_seen: int = 1
    trajectory: str = "flat"
    eliminated_at_round: int | None = None
    history_games: int = 0
    history_win_rate: float | None = None
    rank_vs_history: str | None = None
    history_trend: str | None = None


@dataclass(slots=True)
class GameSignals:
    rounds_count: int
    lead_changes: int
    decided_at_round: int | None
    margin_first_to_second: int
    tightness: str
    players: list[PlayerSignals]


def _rank_of(totals: dict[int, int], lowest_wins: bool) -> dict[int, int]:
    """Dense rank over totals, in the direction the game is scored."""
    ordered = sorted(set(totals.values()), reverse=not lowest_wins)
    position = {value: i + 1 for i, value in enumerate(ordered)}
    return {pid: position[value] for pid, value in totals.items()}


def _percentile(rank: int | None, total_players: int | None) -> float | None:
    """0.0 for a win, 1.0 for last place, so different table sizes compare."""
    if not rank or not total_players or total_players < 1 or rank < 1:
        return None
    if total_players == 1:
        return 0.0
    return (rank - 1) / (total_players - 1)


def _consistency(values: list[int]) -> str:
    if len(values) < 2:
        return "steady"
    spread = statistics.pstdev(values)
    scale = max(1.0, abs(statistics.fmean(values)))
    ratio = spread / scale
    if ratio <= 0.5:
        return "steady"
    return "uneven" if ratio <= 1.2 else "erratic"


def _trajectory(final_rank: int, best_seen: int, worst_seen: int) -> str:
    if worst_seen - final_rank >= 2:
        return "comeback"
    if final_rank - best_seen >= 2:
        return "collapse"
    return "flat"


def _is_dead(total: int, rules: GameRules) -> bool:
    threshold = rules.player_dead_threshold
    if threshold is None:
        return False
    if rules.player_dead_condition_type == "over":
        return total > threshold
    if rules.player_dead_condition_type == "under":
        return total < threshold
    return False


def _history_signals(entries: list[dict[str, Any]], today: float | None) -> dict[str, Any]:
    out: dict[str, Any] = {
        "history_games": len(entries),
        "history_win_rate": None,
        "rank_vs_history": None,
        "history_trend": None,
    }
    if not entries:
        return out

    wins = sum(1 for e in entries if e.get("didWin") or e.get("did_win"))
    out["history_win_rate"] = wins / len(entries)

    # Most recent first, as the repository returns them (drift_repositories.dart).
    percentiles: list[float] = []
    for e in entries:
        # The app sends camelCase aliases; a hand-written payload may use snake_case.
        total_players = e.get("totalPlayers")
        if total_players is None:
            total_players = e.get("total_players")
        pct = _percentile(e.get("rank"), total_players)
        if pct is not None:
            percentiles.append(pct)
    if not percentiles:
        return out

    usual = statistics.fmean(percentiles)
    if today is not None:
        delta = today - usual
        if delta <= -_RANK_SHIFT_THRESHOLD:
            out["rank_vs_history"] = "above their usual"
        elif delta >= _RANK_SHIFT_THRESHOLD:
            out["rank_vs_history"] = "below their usual"
        else:
            out["rank_vs_history"] = "in line with their usual"

    if len(percentiles) >= _TREND_MIN_GAMES:
        chronological = list(reversed(percentiles))
        half = len(chronological) // 2
        earlier = statistics.fmean(chronological[:half])
        later = statistics.fmean(chronological[half:])
        drift = later - earlier
        if drift <= -_RANK_SHIFT_THRESHOLD:
            out["history_trend"] = "improving"
        elif drift >= _RANK_SHIFT_THRESHOLD:
            out["history_trend"] = "declining"
        else:
            out["history_trend"] = "flat"
    return out


def compute_signals(payload: dict[str, Any], rules: GameRules) -> GameSignals:
    """Everything the model must judge but must not recite."""
    players: list[dict[str, Any]] = payload.get("players") or []
    rounds = sorted(payload.get("rounds") or [], key=lambda r: r.get("number") or 0)
    history = payload.get("history_by_player_name") or {}
    lowest_wins = bool(rules.is_lowest_score_wins)

    totals: dict[int, int] = {p["id"]: 0 for p in players}
    played: dict[int, list[int]] = {p["id"]: [] for p in players}
    per_round: dict[int, list[tuple[int, int]]] = {p["id"]: [] for p in players}
    best_rank: dict[int, int] = {p["id"]: len(players) for p in players}
    worst_rank: dict[int, int] = {p["id"]: 1 for p in players}
    in_lead: dict[int, int] = {p["id"]: 0 for p in players}
    eliminated: dict[int, int | None] = {p["id"]: None for p in players}

    lead_changes = 0
    decided_at: int | None = None
    previous_leaders: tuple[int, ...] | None = None

    for r in rounds:
        number = r.get("number") or 0
        by_pid = {s["player_id"]: s.get("value") for s in (r.get("scores") or [])}
        for p in players:
            pid = p["id"]
            value = by_pid.get(pid)
            if value is None:
                continue  # the player sat this round out
            totals[pid] += value
            played[pid].append(value)
            per_round[pid].append((number, value))
            if eliminated[pid] is None and _is_dead(totals[pid], rules):
                eliminated[pid] = number

        ranks = _rank_of(totals, lowest_wins)
        leaders = tuple(sorted(pid for pid, rank in ranks.items() if rank == 1))
        for pid, rank in ranks.items():
            best_rank[pid] = min(best_rank[pid], rank)
            worst_rank[pid] = max(worst_rank[pid], rank)
            if rank == 1:
                in_lead[pid] += 1
        if previous_leaders is not None and leaders != previous_leaders:
            lead_changes += 1
            decided_at = number
        previous_leaders = leaders

    final_ranks = _rank_of(totals, lowest_wins)
    signals: list[PlayerSignals] = []
    for p in players:
        pid = p["id"]
        values = played[pid]
        scored = per_round[pid]
        rank = final_ranks[pid]
        today = _percentile(rank, len(players))
        best = worst = None
        if scored:
            best = min(scored, key=lambda rv: rv[1] if lowest_wins else -rv[1])
            worst = max(scored, key=lambda rv: rv[1] if lowest_wins else -rv[1])
        ps = PlayerSignals(
            name=p["name"],
            total=totals[pid],
            rank=rank,
            tied_with=[
                q["name"] for q in players if q["id"] != pid and final_ranks[q["id"]] == rank
            ],
            rounds_played=len(values),
            best_round=best,
            worst_round=worst,
            consistency=_consistency(values),
            rounds_in_lead=in_lead[pid],
            best_rank_seen=best_rank[pid] if rounds else rank,
            worst_rank_seen=worst_rank[pid] if rounds else rank,
            trajectory=_trajectory(rank, best_rank[pid], worst_rank[pid]) if rounds else "flat",
            eliminated_at_round=eliminated[pid],
        )
        for key, value in _history_signals(history.get(p["name"]) or [], today).items():
            setattr(ps, key, value)
        signals.append(ps)

    signals.sort(key=lambda s: (s.rank, s.name))

    margin = 0
    if len(signals) >= 2:
        margin = abs(signals[0].total - signals[1].total)
    all_values = [v for vals in played.values() for v in vals]
    typical = statistics.fmean([abs(v) for v in all_values]) if all_values else 0.0
    if typical <= 0:
        tightness = "photo finish" if margin == 0 else "blowout"
    else:
        ratio = margin / typical
        tightness = "photo finish" if ratio <= 0.5 else "close" if ratio <= 2 else "blowout"

    return GameSignals(
        rounds_count=len(rounds),
        lead_changes=lead_changes,
        decided_at_round=decided_at,
        margin_first_to_second=margin,
        tightness=tightness,
        players=signals,
    )


def render_signals(signals: GameSignals) -> str:
    """The compact block handed to the model, labels first."""
    lines = ["## Derived facts (for your judgement — never quote them back)"]
    if signals.rounds_count == 0:
        lines.append("")
        lines.append("No round was played, so there is nothing to judge but the intention.")
        return "\n".join(lines)

    lines.append("")
    lines.append(f"- Finish: {signals.tightness}")
    lines.append(f"- Lead changes: {signals.lead_changes}")
    if signals.decided_at_round is not None:
        lines.append(f"- Last time the lead changed hands: round {signals.decided_at_round}")
    lines.append("")

    for p in signals.players:
        bits = [
            f"final total {p.total}",
            f"rank {p.rank}" + (f" (tied with {', '.join(p.tied_with)})" if p.tied_with else ""),
            f"{p.consistency} across their rounds",
            f"led for {p.rounds_in_lead} of {signals.rounds_count} rounds",
            f"trajectory: {p.trajectory}",
        ]
        if p.best_round and p.worst_round and p.best_round != p.worst_round:
            bits.append(f"best round {p.best_round[0]}, worst round {p.worst_round[0]}")
        if p.eliminated_at_round is not None:
            bits.append(f"eliminated at round {p.eliminated_at_round}")
        if p.rounds_played < signals.rounds_count:
            bits.append(f"sat out {signals.rounds_count - p.rounds_played} rounds")
        if p.history_games:
            plural = "" if p.history_games == 1 else "s"
            bits.append(f"{p.history_games} earlier game{plural} on record")
            if p.rank_vs_history:
                bits.append(f"finished {p.rank_vs_history}")
            if p.history_trend:
                bits.append(f"form over those games: {p.history_trend}")
            if p.history_win_rate is not None:
                bits.append(f"wins about {round(p.history_win_rate * 100)}% of the time")
        else:
            bits.append("no earlier game on record")
        lines.append(f"- {p.name}: " + "; ".join(bits))

    return "\n".join(lines)
