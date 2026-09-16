"""Assembles the two messages sent to the provider.

Nothing in this package ever learns which provider will receive the prompt: the analysis
prompt is the control variable that makes `scripts/compare_providers.py` meaningful
(.llmwiki/LlmProviders.md, backend/CLAUDE.md rule 4), and keeping the provider out of the
signature is what makes that structural rather than a matter of discipline.
"""

from __future__ import annotations

import html
from typing import Any

from .contract import ANTI_INJECTION, EDITORIAL_CONTRACT, ROLE, SAFETY
from .game_rules import (
    GameRules,
    describe_rules,
    normalise_game_over_condition,
    normalise_player_dead_condition,
)
from .languages import resolve_language
from .personas import PERSONAS, resolve_persona
from .signals import compute_signals, render_signals

# A long game is where the input cost lives: 200 rounds by 12 players is a five-figure
# token count for a table the model is forbidden to reproduce anyway. The derived facts
# carry the judgement, so the table only has to show how the game opened and how it ended.
_TABLE_HEAD_ROUNDS = 3
_TABLE_TAIL_ROUNDS = 40


def _safe(value: object) -> str:
    """Escape for the XML-ish tags, and keep a hostile value on one harmless line.

    Flattening the newlines is what stops a player name or a game type from opening a
    Markdown heading of its own in the middle of the prompt; the leading ``#`` goes with
    them so the first line cannot do it either.
    """
    text = "" if value is None else str(value)
    text = text.replace("\r", " ").replace("\n", " ").strip().lstrip("#").strip()
    return html.escape(text, quote=False)


def _rules_from_payload(payload: dict[str, Any]) -> GameRules:
    game = payload.get("game") or {}
    raw = payload.get("game_type_rules") or {}
    lowest = raw.get("is_lowest_score_wins")
    if lowest is None:
        lowest = game.get("is_lowest_score_wins")
    return GameRules(
        is_lowest_score_wins=bool(lowest),
        player_dead_condition_type=normalise_player_dead_condition(
            raw.get("player_dead_condition_type")
        ),
        player_dead_threshold=raw.get("player_dead_threshold"),
        game_over_condition_type=normalise_game_over_condition(raw.get("game_over_condition_type")),
        game_over_threshold=raw.get("game_over_threshold"),
    )


def build_system_prompt(payload: dict[str, Any]) -> str:
    """Role, language, persona, rules of the game, contract, safety, defences."""
    persona = resolve_persona(payload.get("style"))
    language = resolve_language(payload.get("language"))
    rules = describe_rules(payload.get("game_type"), _rules_from_payload(payload))

    return "\n\n".join(
        [
            ROLE,
            language.directive,
            "## Your voice\n\n" + PERSONAS[persona],
            "## The game\n\n" + rules,
            EDITORIAL_CONTRACT,
            SAFETY,
            ANTI_INJECTION,
            language.directive,
        ]
    )


def _round_table(payload: dict[str, Any]) -> list[str]:
    players = payload.get("players") or []
    rounds = sorted(payload.get("rounds") or [], key=lambda r: r.get("number") or 0)
    lines: list[str] = ["## Rounds"]
    if not rounds:
        lines.append("No round was recorded.")
        return lines

    columns = "".join(f" <player_name>{_safe(p['name'])}</player_name> |" for p in players)
    lines.append("| Round |" + columns + " Note |")
    lines.append("|---|" + "---|" * len(players) + "---|")

    elided = False
    cumulative: dict[int, int] = {p["id"]: 0 for p in players}
    keep_from = len(rounds) - _TABLE_TAIL_ROUNDS
    for i, r in enumerate(rounds):
        by_pid = {s["player_id"]: s.get("value") for s in (r.get("scores") or [])}
        row = f"| {r.get('number')} |"
        for p in players:
            value = by_pid.get(p["id"])
            if value is None:
                row += " — |"
            else:
                cumulative[p["id"]] += value
                row += f" {value} ({cumulative[p['id']]}) |"
        row += f" {_safe(r.get('comment'))} |"
        # Cumulative totals must stay correct, so every round is still summed; only the
        # middle of a long game is left out of the rendering.
        if i < _TABLE_HEAD_ROUNDS or i >= keep_from:
            lines.append(row)
        elif not elided:
            omitted = len(rounds) - _TABLE_HEAD_ROUNDS - _TABLE_TAIL_ROUNDS
            lines.append(f"| … | {omitted} rounds omitted |")
            elided = True
    return lines


def build_user_message(payload: dict[str, Any]) -> str:
    """The data block: the game, its rounds, the derived facts, each player's record.

    Labels are English because this is *data*: the output language is a separate
    instruction, and French labels arguing with a "reply in Japanese" directive is a real
    compliance risk.
    """
    game = payload.get("game") or {}
    players = payload.get("players") or []
    history = payload.get("history_by_player_name") or {}

    lines: list[str] = [
        "# Game to analyse",
        "",
        f"- Name: {_safe(game.get('name'))}",
        f"- Date: {_safe(game.get('created_at'))}",
        f"- Game type: <game_type>{_safe(payload.get('game_type')) or 'unknown'}</game_type>",
        f"- Players: {len(players)}",
        "",
        "## Players",
    ]
    lines += [f"- <player_name>{_safe(p['name'])}</player_name>" for p in players]
    lines.append("")
    lines += _round_table(payload)
    lines.append("")
    lines.append(render_signals(compute_signals(payload, _rules_from_payload(payload))))
    lines.append("")

    lines.append("## Each player's earlier games (up to 10, this one excluded)")
    for p in players:
        lines.append("")
        lines.append(f"### <player_name>{_safe(p['name'])}</player_name>")
        entries = history.get(p["name"]) or []
        if not entries:
            lines.append("No earlier game on record.")
            continue
        for h in entries:
            mark = "won — " if (h.get("didWin") or h.get("did_win")) else ""
            date = h.get("createdAt") or h.get("created_at") or h.get("date") or ""
            name = h.get("gameName") or h.get("game_name")
            kind = h.get("gameType") or h.get("game_type")
            total = h.get("totalPlayers") or h.get("total_players")
            lines.append(
                f"- {mark}{_safe(date)} — {_safe(name)} ({_safe(kind)}): "
                f"rank {h.get('rank')}/{total}"
            )

    return "\n".join(lines)


def build_analysis_prompt(payload: dict[str, Any]) -> tuple[str, str]:
    """The (system, user) pair for one analysis."""
    return build_system_prompt(payload), build_user_message(payload)
