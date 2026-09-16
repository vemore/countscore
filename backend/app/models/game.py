"""Game-related models: GameType, Game, GamePlayer (join), Round, Score, GameAnalysis."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import BigInteger, Column, DateTime, ForeignKey, Index, Text
from sqlmodel import Field, SQLModel

from app.models._indexes import live_unique


def _utcnow() -> datetime:
    return datetime.now(UTC)


class GameType(SQLModel, table=True):
    __tablename__ = "game_types"
    __table_args__ = (
        Index("ix_game_types_group_id", "group_id"),
        live_unique("uq_game_types_group_name", "group_id", "name"),
    )

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    group_id: uuid.UUID = Field(
        sa_column=Column(ForeignKey("groups.id", ondelete="CASCADE"), nullable=False)
    )
    name: str = Field(max_length=64)
    icon_code_point: int
    # ARGB as Flutter's Color.toARGB32() — opaque colours exceed the int32 range.
    card_color_value: int = Field(sa_column=Column(BigInteger, nullable=False))
    is_lowest_score_wins: bool = Field(default=False)
    is_default: bool = Field(default=False)
    player_dead_condition_type: str | None = Field(default=None, max_length=16)
    player_dead_threshold: int | None = Field(default=None)
    game_over_condition_type: str | None = Field(default=None, max_length=32)
    game_over_threshold: int | None = Field(default=None)
    # The rules the group wrote for this type, as Markdown. NULL means the app
    # shows the ruleset it ships for ``rules_slug`` instead.
    rules: str | None = Field(default=None, sa_column=Column(Text, nullable=True))
    # Names a ruleset shipped in the app's ``assets/rules/``. Kept apart from
    # ``name`` because the name is user-editable.
    rules_slug: str | None = Field(default=None, max_length=32)

    created_at: datetime = Field(
        default_factory=_utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False),
    )
    updated_at: datetime = Field(
        default_factory=_utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False),
    )
    deleted_at: datetime | None = Field(
        default=None,
        sa_column=Column(DateTime(timezone=True), nullable=True),
    )


class Game(SQLModel, table=True):
    __tablename__ = "games"
    __table_args__ = (Index("ix_games_group_id", "group_id"),)

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    group_id: uuid.UUID = Field(
        sa_column=Column(ForeignKey("groups.id", ondelete="CASCADE"), nullable=False)
    )
    name: str = Field(max_length=64)
    game_type_id: uuid.UUID | None = Field(
        default=None,
        sa_column=Column(ForeignKey("game_types.id", ondelete="SET NULL"), nullable=True),
    )
    is_lowest_score_wins: bool = Field(default=False)
    started_at: datetime = Field(
        default_factory=_utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False),
    )
    ended_at: datetime | None = Field(
        default=None,
        sa_column=Column(DateTime(timezone=True), nullable=True),
    )

    created_at: datetime = Field(
        default_factory=_utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False),
    )
    updated_at: datetime = Field(
        default_factory=_utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False),
    )
    deleted_at: datetime | None = Field(
        default=None,
        sa_column=Column(DateTime(timezone=True), nullable=True),
    )


class GamePlayer(SQLModel, table=True):
    """Many-to-many join between games and players (with per-game ordering and color)."""

    __tablename__ = "game_players"

    game_id: uuid.UUID = Field(
        sa_column=Column(ForeignKey("games.id", ondelete="CASCADE"), primary_key=True)
    )
    player_id: uuid.UUID = Field(
        sa_column=Column(ForeignKey("players.id", ondelete="CASCADE"), primary_key=True)
    )
    order_index: int
    color_value: int | None = Field(default=None, sa_column=Column(BigInteger, nullable=True))


class Round(SQLModel, table=True):
    __tablename__ = "rounds"
    __table_args__ = (
        live_unique("uq_rounds_game_number", "game_id", "round_number"),
        Index("ix_rounds_game_id", "game_id"),
    )

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    game_id: uuid.UUID = Field(
        sa_column=Column(ForeignKey("games.id", ondelete="CASCADE"), nullable=False)
    )
    round_number: int
    comment: str | None = Field(default=None, sa_column=Column(Text, nullable=True))

    created_at: datetime = Field(
        default_factory=_utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False),
    )
    updated_at: datetime = Field(
        default_factory=_utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False),
    )
    deleted_at: datetime | None = Field(
        default=None,
        sa_column=Column(DateTime(timezone=True), nullable=True),
    )


class Score(SQLModel, table=True):
    __tablename__ = "scores"
    __table_args__ = (
        live_unique("uq_scores_player_round", "player_id", "round_id"),
        Index("ix_scores_round_id", "round_id"),
    )

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    player_id: uuid.UUID = Field(
        sa_column=Column(ForeignKey("players.id", ondelete="CASCADE"), nullable=False)
    )
    round_id: uuid.UUID = Field(
        sa_column=Column(ForeignKey("rounds.id", ondelete="CASCADE"), nullable=False)
    )
    value: int

    created_at: datetime = Field(
        default_factory=_utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False),
    )
    updated_at: datetime = Field(
        default_factory=_utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False),
    )
    deleted_at: datetime | None = Field(
        default=None,
        sa_column=Column(DateTime(timezone=True), nullable=True),
    )


class GameAnalysis(SQLModel, table=True):
    """The long-form analysis of a game, shared so members do not pay for it twice."""

    __tablename__ = "game_analyses"
    __table_args__ = (live_unique("uq_game_analyses_game", "game_id"),)

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    game_id: uuid.UUID = Field(
        sa_column=Column(ForeignKey("games.id", ondelete="CASCADE"), nullable=False)
    )
    content: str = Field(sa_column=Column(Text, nullable=False))
    model_id: str | None = Field(default=None, max_length=128)
    generated_at: datetime = Field(
        default_factory=_utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False),
    )

    created_at: datetime = Field(
        default_factory=_utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False),
    )
    updated_at: datetime = Field(
        default_factory=_utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False),
    )
    deleted_at: datetime | None = Field(
        default=None,
        sa_column=Column(DateTime(timezone=True), nullable=True),
    )
