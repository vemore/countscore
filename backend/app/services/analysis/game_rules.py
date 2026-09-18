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
        "ZapZap is a family card game, a variant of Yaniv, where each player tries to hold "
        "the lowest hand. Aces count 1, number cards their face value, Jack 11, Queen 12, "
        "King 13; a Joker counts 0 during play but 25 if it is still in hand at the count. "
        "The player who opens a round chooses the hand size, 4 to 7 cards. On a turn a "
        "player first lays down a single card, a set of the same rank, or a run of three or "
        "more consecutive cards of one suit, then draws one card, from the deck or from the "
        "cards the previous player just laid down. Instead of playing, a player whose hand "
        'is worth 5 points or less may call "ZapZap", which ends the round. The lowest hand '
        "scores 0; everyone else scores their hand. The caller is countered when another "
        "player holds an equal or lower hand, and then scores their hand plus (players "
        "still in - 1) x 5. Read the scores accordingly: a 0 is the lowest hand of the "
        "round, usually a successful call, and a very high round is a call that was "
        "countered or a hand caught full of high cards and Jokers. A player who scores very "
        "low in a round where everyone else scored high called early and caught the table "
        "with their hands full. A single huge score late in the game is a desperate attempt "
        "by someone with their back to the wall. A player is eliminated past 100 points, "
        "and final standing follows elimination order reversed: the last player eliminated "
        "finishes first. With two players left, the final round is a golden score: the "
        "lower hand of that round wins the game whatever the totals, a countered caller "
        "loses it, and the loser is taken to exactly 101."
    ),
    "uno": (
        "A fast card game played in short rounds. The player who goes out first collects "
        "the value of the cards left in everyone else's hand, number cards at face value, "
        "action cards 20, wild cards 50, and the game usually runs to 500 points, highest "
        "total winning; some tables score it the other way round, each player taking what "
        "was left in their own hand as a penalty. A big round means catching the table "
        "with hands full of special cards. Rounds are quick, so a total is built from many "
        "small hauls rather than one windfall."
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
        "and the pecking order at the table carries from one hand to the next. The usual "
        "count gives 2 points to the President and 1 to the Vice-President each hand, "
        "played to 10, highest total winning. Scores are small integers, so the story is "
        "in streaks: who stayed at the top, who got stuck at the bottom and could not "
        "climb back."
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
