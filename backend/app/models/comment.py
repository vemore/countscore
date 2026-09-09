"""Claude-generated comment on a game."""
from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import Column, DateTime, ForeignKey, Index
from sqlmodel import Field, SQLModel


def _utcnow() -> datetime:
    return datetime.now(UTC)


class Comment(SQLModel, table=True):
    __tablename__ = "comments"
    __table_args__ = (
        Index("ix_comments_group_created", "group_id", "created_at"),
        Index("ix_comments_game_id", "game_id"),
    )

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    group_id: uuid.UUID = Field(
        sa_column=Column(ForeignKey("groups.id", ondelete="CASCADE"), nullable=False)
    )
    game_id: uuid.UUID = Field(
        sa_column=Column(ForeignKey("games.id", ondelete="CASCADE"), nullable=False)
    )
    created_by_device_id: uuid.UUID = Field(
        sa_column=Column(ForeignKey("devices.id", ondelete="SET NULL"), nullable=True)
    )

    content: str
    style: str = Field(max_length=16)
    language: str = Field(max_length=8)
    # SHA-256 of the rounds+scores at generation time. Allows UI to flag stale comments.
    scores_hash: str = Field(max_length=64)
    # SHA-256 of the full prompt — for audit and dedup detection.
    prompt_hash: str = Field(max_length=64)
    model: str = Field(max_length=64)
    tokens_in: int = Field(default=0)
    tokens_out: int = Field(default=0)
    # Stored as an int; cents * 100 would give "milli-cents" if we ever need more precision.
    cost_cents: int = Field(default=0)

    created_at: datetime = Field(
        default_factory=_utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False),
    )
