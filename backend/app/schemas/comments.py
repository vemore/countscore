"""Pydantic schemas for comment endpoints."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

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
