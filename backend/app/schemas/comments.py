"""Pydantic schemas for comment endpoints."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Annotated, Literal

from pydantic import BaseModel, BeforeValidator, ConfigDict, Field, model_validator

from app.models.player import sanitize_player_name

CommentStyle = Literal["narrative", "humorous", "analytical"]


class GenerateCommentRequest(BaseModel):
    style_override: CommentStyle | None = None


class CommentPayload(BaseModel):
    id: uuid.UUID
    game_id: uuid.UUID
    content: str
    style: CommentStyle
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


# ZapZap analysis — the payload GameAnalysisScreen._generate builds
# (lib/screens/game_analysis_screen.dart). Every text field ends up verbatim in an LLM
# prompt, but the app never bounded any of them locally, so this schema does not refuse
# a game over its text: it clips strings and filters player names, and returns 422 only
# for a wrong shape or a count out of bounds. See .llmwiki/LlmProviders.md.

_ZAPZAP_MAX_PLAYERS = 12
_ZAPZAP_MAX_ROUNDS = 200
_ZAPZAP_MAX_HISTORY = 10
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


class ZapZapGame(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: int | None = None
    name: ShortText
    is_lowest_score_wins: bool
    created_at: Timestamp


class ZapZapPlayer(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: int
    name: RawPlayerName


class ZapZapScore(BaseModel):
    model_config = ConfigDict(extra="ignore")

    player_id: int
    value: Score | None = None


class ZapZapRound(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: int | None = None
    number: int = Field(ge=0, le=10_000)
    comment: RoundComment | None = None
    scores: list[ZapZapScore] = Field(max_length=_ZAPZAP_MAX_PLAYERS)


class ZapZapHistoryEntry(BaseModel):
    model_config = ConfigDict(extra="ignore", populate_by_name=True)

    game_name: ShortText | None = Field(default=None, alias="gameName")
    game_type: ShortText | None = Field(default=None, alias="gameType")
    date: Timestamp | None = None
    created_at: Timestamp | None = Field(default=None, alias="createdAt")
    final_score: Score | None = Field(default=None, alias="finalScore")
    total_players: int | None = Field(default=None, ge=0, le=1_000, alias="totalPlayers")
    rank: int | None = Field(default=None, ge=0, le=1_000)
    did_win: bool | None = Field(default=None, alias="didWin")


class ZapZapPayload(BaseModel):
    model_config = ConfigDict(extra="ignore")

    game: ZapZapGame
    game_type: ShortText | None = None
    players: list[ZapZapPlayer] = Field(min_length=1, max_length=_ZAPZAP_MAX_PLAYERS)
    rounds: list[ZapZapRound] = Field(max_length=_ZAPZAP_MAX_ROUNDS)
    history_by_player_name: dict[
        RawPlayerName, Annotated[list[ZapZapHistoryEntry], Field(max_length=_ZAPZAP_MAX_HISTORY)]
    ] = Field(default_factory=dict, max_length=_ZAPZAP_MAX_PLAYERS)

    @model_validator(mode="after")
    def _filter_player_names(self) -> ZapZapPayload:
        """Put every player name through the sync path's allow-list, as a filter.

        History is re-keyed by the filtered name, so the prompt still finds it; entries
        under a name that is no player of this game are dropped.
        """
        history: dict[str, list[ZapZapHistoryEntry]] = {}
        for i, player in enumerate(self.players, start=1):
            raw = player.name
            player.name = sanitize_player_name(raw) or f"Joueur {i}"
            if raw in self.history_by_player_name:
                history[player.name] = self.history_by_player_name[raw]
        self.history_by_player_name = history
        return self
