"""Pydantic schemas for comment endpoints."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Annotated, Literal

from pydantic import AfterValidator, BaseModel, BeforeValidator, ConfigDict, Field, model_validator

from app.models.player import sanitize_player_name
from app.services.analysis import DEFAULT_PERSONA, resolve_persona

CommentStyle = Literal["narrative", "humorous", "analytical"]


class CommentPayload(BaseModel):
    id: uuid.UUID
    game_id: uuid.UUID
    content: str
    # One of the three group styles for a comment the Anthropic path wrote, or one of
    # the nine analysis voices (``PersonaKey``) for a shared game's analysis.
    style: str
    language: str
    model: str
    scores_hash: str
    tokens_in: int
    tokens_out: int
    cost_cents: int
    created_at: datetime


# Stateless MVP endpoint — accepts a full game payload without any group context.
# This is used by /comments/mvp (Jalon 4) before groups exist on a given device.


class MvpPlayer(BaseModel):
    uuid: str
    name: str = Field(min_length=1, max_length=32)


class MvpRoundScore(BaseModel):
    player_uuid: str = Field(min_length=1, max_length=64)
    # Same generous bound as the sync path — see app/services/delta_bounds.py. Values
    # here are rendered straight into an LLM prompt, so they are size-capped too.
    value: int = Field(ge=-1_000_000, le=1_000_000)


class MvpRound(BaseModel):
    n: int = Field(ge=0, le=10_000)
    scores: list[MvpRoundScore] = Field(max_length=12)


class MvpGamePayload(BaseModel):
    game_name: str = Field(min_length=1, max_length=64)
    game_type: str = Field(min_length=1, max_length=64)
    is_lowest_score_wins: bool
    players: list[MvpPlayer] = Field(min_length=1, max_length=12)
    rounds: list[MvpRound] = Field(min_length=1, max_length=200)
    style: CommentStyle = "narrative"
    language: str = Field(default="fr", min_length=2, max_length=8)


class MvpCommentResponse(BaseModel):
    content: str
    model: str
    tokens_in: int
    tokens_out: int


# Game analysis — the payload GameAnalysisScreen._generate builds
# (lib/screens/game_analysis_screen.dart). Every text field ends up verbatim in an LLM
# prompt, but the app never bounded any of them locally, so this schema does not refuse
# a game over its text: it clips strings and filters player names, and returns 422 only
# for a wrong shape or a count out of bounds. See .llmwiki/LlmProviders.md.

_MAX_PLAYERS = 12
_MAX_ROUNDS = 200
_MAX_HISTORY = 10
_SCORE_BOUND = 1_000_000


def _clipped(max_length: int) -> BeforeValidator:
    return BeforeValidator(lambda v: v[:max_length] if isinstance(v, str) else v)


ShortText = Annotated[str, _clipped(64)]
Timestamp = Annotated[str, _clipped(40)]
RoundComment = Annotated[str, _clipped(200)]
# Clipped generously before filtering: the filter needs the raw name to match history
# keys, and only has to keep a hostile name from being large, not from being odd.
RawPlayerName = Annotated[str, _clipped(256)]
Score = Annotated[int, Field(ge=-_SCORE_BOUND, le=_SCORE_BOUND)]
# A style or a locale the backend does not know is corrected, never refused: the only
# client is the app, and a newer app against an older backend — or the reverse — must
# still get its analysis. A cosmetic field is not worth losing one over.
AnalysisStyle = Annotated[str, _clipped(32), AfterValidator(resolve_persona)]
LanguageTag = Annotated[str, _clipped(16)]
# Same reasoning for the two condition enums: an unknown value means "no such condition",
# which is exactly what an older client that never sent one produces.
ConditionName = Annotated[str, _clipped(32)]


class AnalysisGame(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: int | None = None
    name: ShortText
    is_lowest_score_wins: bool
    created_at: Timestamp


class AnalysisPlayer(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: int
    name: RawPlayerName


class AnalysisScore(BaseModel):
    model_config = ConfigDict(extra="ignore")

    player_id: int
    value: Score | None = None


class AnalysisRound(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: int | None = None
    number: int = Field(ge=0, le=10_000)
    comment: RoundComment | None = None
    scores: list[AnalysisScore] = Field(max_length=_MAX_PLAYERS)


class AnalysisHistoryEntry(BaseModel):
    model_config = ConfigDict(extra="ignore", populate_by_name=True)

    game_name: ShortText | None = Field(default=None, alias="gameName")
    game_type: ShortText | None = Field(default=None, alias="gameType")
    date: Timestamp | None = None
    created_at: Timestamp | None = Field(default=None, alias="createdAt")
    final_score: Score | None = Field(default=None, alias="finalScore")
    total_players: int | None = Field(default=None, ge=0, le=1_000, alias="totalPlayers")
    rank: int | None = Field(default=None, ge=0, le=1_000)
    did_win: bool | None = Field(default=None, alias="didWin")


class GameTypeRules(BaseModel):
    """The scoring configuration of the game type, mirroring lib/models/game_type.dart.

    Absent from a client older than the multi-game-type analysis, in which case the
    builder falls back to ``game.is_lowest_score_wins``, which every version sends.
    """

    model_config = ConfigDict(extra="ignore")

    is_lowest_score_wins: bool | None = None
    player_dead_condition_type: ConditionName | None = None
    player_dead_threshold: Score | None = None
    game_over_condition_type: ConditionName | None = None
    game_over_threshold: Score | None = None


class GameAnalysisPayload(BaseModel):
    model_config = ConfigDict(extra="ignore")

    game: AnalysisGame
    game_type: ShortText | None = None
    style: AnalysisStyle = DEFAULT_PERSONA
    language: LanguageTag = "fr"
    game_type_rules: GameTypeRules | None = None
    players: list[AnalysisPlayer] = Field(min_length=1, max_length=_MAX_PLAYERS)
    rounds: list[AnalysisRound] = Field(max_length=_MAX_ROUNDS)
    history_by_player_name: dict[
        RawPlayerName, Annotated[list[AnalysisHistoryEntry], Field(max_length=_MAX_HISTORY)]
    ] = Field(default_factory=dict, max_length=_MAX_PLAYERS)

    @model_validator(mode="after")
    def _filter_player_names(self) -> GameAnalysisPayload:
        """Put every player name through the sync path's allow-list, as a filter.

        History is re-keyed by the filtered name, so the prompt still finds it; entries
        under a name that is no player of this game are dropped.
        """
        history: dict[str, list[AnalysisHistoryEntry]] = {}
        for i, player in enumerate(self.players, start=1):
            raw = player.name
            player.name = sanitize_player_name(raw) or f"Player {i}"
            if raw in self.history_by_player_name:
                history[player.name] = self.history_by_player_name[raw]
        self.history_by_player_name = history
        return self


class GenerateCommentRequest(BaseModel):
    """Body of ``POST /groups/me/games/{game_id}/comments``.

    Without ``analysis``: the original group comment — the Anthropic path, the prompt
    built from the server's copy of the game, ``style_override`` or the group's style.

    With ``analysis``: the analysis of a shared game, in the very shape
    ``/comments/game-analysis`` takes, through the configured LLM provider — billed to the
    group, in the group's language, and in the voice the payload names, or, when it names
    none, the voice the group's style maps to. See .llmwiki/Api.md.
    """

    style_override: CommentStyle | None = None
    analysis: GameAnalysisPayload | None = None


# The published app posts to /comments/zapzap-analysis with this very shape. The alias
# keeps that name meaningful for one release; the route serves both paths.
ZapZapPayload = GameAnalysisPayload


class GameAnalysisResponse(BaseModel):
    content: str
    model: str
    tokens_in: int
    tokens_out: int
