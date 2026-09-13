"""Player model — global per group (one canonical entity per human player)."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import CheckConstraint, Column, DateTime, ForeignKey, Index
from sqlmodel import Field, SQLModel


def _utcnow() -> datetime:
    return datetime.now(UTC)


# Player name allow-list — prevents prompt injection via player names.
# Permits Unicode letters/numbers, spaces, hyphens, apostrophes, periods.
# Length 1-32 enforced separately (and by ck_player_name_length below).
#
# Kept as the written spec: ``\p{L}``/``\p{N}`` need the third-party ``regex`` module,
# which we do not depend on, so ``is_valid_player_name`` implements the same rule with
# the stdlib. Change both together.
PLAYER_NAME_REGEX = r"^[\p{L}\p{N} \-'.]+$"

PLAYER_NAME_PUNCTUATION = frozenset(" -'.")
PLAYER_NAME_MAX_LENGTH = 32


def is_valid_player_name(name: str) -> bool:
    """The stdlib equivalent of PLAYER_NAME_REGEX, plus the 1-32 length bound.

    ``str.isalpha`` and ``str.isdigit`` are Unicode-aware, so accented and non-Latin
    names pass exactly as the regex intends.
    """
    if not 1 <= len(name) <= PLAYER_NAME_MAX_LENGTH:
        return False
    return all(c.isalpha() or c.isdigit() or c in PLAYER_NAME_PUNCTUATION for c in name)


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
