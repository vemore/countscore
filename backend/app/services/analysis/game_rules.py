"""What the model is told about the game being analysed.

Two parts, always in this order:

1. a prose block for the game type, from a registry keyed on the *normalised* name, or a
   generic block when the name is unknown — the app lets anyone create a game type, so
   most names in the wild will not be in the registry;
2. the configuration the application actually enforced, rendered from the structured
   fields, with an explicit sentence saying it overrides part 1. A user can rename or
   retune a seeded type: the payload is ground truth, the registry is only colour.

The registry blocks describe scoring shape and vocabulary in general terms. They are not
a reproduction of anyone's rulebook, and nothing here invents a rule the application does
not enforce — the generic block says so in as many words.
"""

from __future__ import annotations

import unicodedata
from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class GameRules:
    """The scoring configuration of one game, as the app recorded it."""

    is_lowest_score_wins: bool
    player_dead_condition_type: str | None = None
    player_dead_threshold: int | None = None
    game_over_condition_type: str | None = None
    game_over_threshold: int | None = None


_PLAYER_DEAD_CONDITIONS = ("over", "under")
_GAME_OVER_CONDITIONS = (
    "firstPlayerOver",
    "firstPlayerUnder",
    "lastPlayerOver",
    "lastPlayerUnder",
)


def normalise_condition(value: object, allowed: tuple[str, ...]) -> str | None:
    """Match a condition name case-insensitively; anything else becomes "absent"."""
    if not isinstance(value, str):
        return None
    folded = value.strip().casefold()
    for candidate in allowed:
        if candidate.casefold() == folded:
            return candidate
    return None


def normalise_player_dead_condition(value: object) -> str | None:
    return normalise_condition(value, _PLAYER_DEAD_CONDITIONS)


def normalise_game_over_condition(value: object) -> str | None:
    return normalise_condition(value, _GAME_OVER_CONDITIONS)


def normalise_game_type(name: object) -> str:
    """Fold a game-type name to a registry key: ``Président`` and ``PRESIDENT `` match."""
    if not isinstance(name, str):
        return ""
    decomposed = unicodedata.normalize("NFKD", name)
    stripped = "".join(c for c in decomposed if not unicodedata.combining(c))
    return "".join(c for c in stripped.casefold() if c.isalnum())


# The nine seeded types that have a scoring shape worth describing. "Autre" (Other) is
# deliberately absent: it is the catch-all, and it gets the generic block.
# lib/models/game_type.dart defaultGameTypes().
KNOWN_GAME_TYPES: dict[str, str] = {
    "zapzap": (
        "ZapZap is a card game where each player tries to hold the lowest hand. A player "
        'may call "ZapZap" when they believe their hand is the lowest: if they are right '
        "they score 0 for that round, and if they are wrong or get countered they take "
        "their hand plus a penalty proportional to the number of opponents. Read the "
        "scores accordingly: a 0 is a successful call, a very high round is usually a call "
        "that failed or a hand nobody managed to empty. A player who scores very low in a "
        "round where everyone else scored high called early and caught the table with "
        "their hands full. A single huge score late in the game is a desperate attempt by "
        "someone with their back to the wall. Final standing follows elimination order "
        "reversed: the last player eliminated finishes first."
    ),
    "uno": (
        "A fast card game played in short rounds. Only the players who fail to go out "
        "score, and they score the cards left in their hand, so a round is either a zero "
        "or a penalty. Big numbers mean a hand full of special cards at the wrong moment. "
        "Rounds are quick, so a total is the accumulation of small disasters rather than "
        "one catastrophe."
    ),
    "scrabble": (
        "A word game where points are gains, accumulated word by word. Round scores are "
        "large and vary widely: a high round means a long word, a premium square, or "
        "using every tile at once. A low round means a rack nobody could do anything "
        "with. Consistency matters more than any single brilliant word."
    ),
    "skyjo": (
        "A card game of face-down grids where points are penalties and the aim is to end "
        "a round as low as possible. A negative round is an excellent one. A player who "
        "closes a round without being the lowest usually takes a doubling penalty, which "
        "is where sudden large rounds come from."
    ),
    "president": (
        "A shedding game played in short hands, where finishing order decides the points "
        "and the pecking order at the table carries from one hand to the next. Scores are "
        "small integers, so the story is in streaks: who stayed at the top, who got stuck "
        "at the bottom and could not climb back."
    ),
    "belote": (
        "A trick-taking partnership game played to a target over many deals. Points are "
        "gains and come in large, lumpy amounts: a contract made, a contract gone down, "
        "or a sweep. A round far above the usual means an ambitious contract that paid; a "
        "round near zero means one that did not."
    ),
    "tarot": (
        "A trick-taking game with bidding, scored per deal against a target that depends "
        "on the bid. Points are gains, positive or negative, and swing hard: the taker "
        "either makes the contract or pays for it, and everyone else's round mirrors it. "
        "A run of small rounds means a player who kept passing."
    ),
    "bridge": (
        "A trick-taking partnership game with bidding, scored per deal. Points are gains. "
        "The magnitudes come from contract level, vulnerability and penalties rather than "
        "from how many tricks were taken, so a large round means a bid that mattered."
    ),
    "rami": (
        "A rummy-style game where points are penalties: you score the cards still in your "
        "hand when someone goes out. A 0 means going out first, and a large round means "
        "being caught with high cards or a melded hand that never came together."
    ),
}

_GENERIC_BLOCK = (
    "You do not know the rules of this game beyond what the application recorded. Do not "
    "invent any: no card names, no special moves, no scoring particularity, no rule you "
    "were not given. Judge the players on the shape of their scores alone — who kept "
    "their rounds tight, who blew up, who recovered."
)

_DIRECTION = {
    True: "Points are penalties: the lowest total wins.",
    False: "Points are gains: the highest total wins.",
}

_PLAYER_DEAD = {
    "over": "A player is eliminated as soon as their running total goes above {threshold}.",
    "under": "A player is eliminated as soon as their running total falls below {threshold}.",
}

_GAME_OVER = {
    "firstPlayerOver": "The game ends as soon as one player's total goes above {threshold}.",
    "firstPlayerUnder": "The game ends as soon as one player's total falls below {threshold}.",
    "lastPlayerOver": "The game ends once every player's total has gone above {threshold}.",
    "lastPlayerUnder": "The game ends once every player's total has fallen below {threshold}.",
}


def _configuration(rules: GameRules) -> list[str]:
    lines = [_DIRECTION[bool(rules.is_lowest_score_wins)]]
    dead = _PLAYER_DEAD.get(rules.player_dead_condition_type or "")
    if dead is not None and rules.player_dead_threshold is not None:
        lines.append(dead.format(threshold=rules.player_dead_threshold))
    over = _GAME_OVER.get(rules.game_over_condition_type or "")
    if over is not None and rules.game_over_threshold is not None:
        lines.append(over.format(threshold=rules.game_over_threshold))
    return lines


def describe_rules(game_type: object, rules: GameRules) -> str:
    """Compose the rules section of the system prompt."""
    key = normalise_game_type(game_type)
    block = KNOWN_GAME_TYPES.get(key, _GENERIC_BLOCK)
    configuration = "\n".join(f"- {line}" for line in _configuration(rules))
    return (
        f"{block}\n\n"
        "The settings below are what the application actually enforced for this game, and "
        "they override anything above — a player may rename or retune a game type:\n"
        f"{configuration}"
    )
