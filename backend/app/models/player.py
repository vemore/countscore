"""Player model — global per group (one canonical entity per human player)."""
from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import CheckConstraint, Column, DateTime, ForeignKey, Index
from sqlmodel import Field, SQLModel


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


# Player name allow-list — prevents prompt injection via player names.
# Permits Unicode letters/numbers, spaces, hyphens, apostrophes, periods.
# Length 1-32 enforced separately.
PLAYER_NAME_REGEX = r"^[\p{L}\p{N} \-'.]+$"


class Player(SQLModel, table=True):
    __tablename__ = "players"
    __table_args__ = (
        Index("ix_players_group_id", "group_id"),
        Index("uq_players_group_name", "group_id", "name_normalized", unique=True),
        CheckConstraint("length(name) BETWEEN 1 AND 32", name="ck_player_name_length"),
    )

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    group_id: uuid.UUID = Field(
        sa_column=Column(ForeignKey("groups.id", ondelete="CASCADE"), nullable=False)
    )
    name: str = Field(max_length=32)
    # lower(trim(name)) — for the UNIQUE(group, name) constraint without imposing case sensitivity
    name_normalized: str = Field(max_length=32)
    color_value: int | None = Field(default=None)

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
