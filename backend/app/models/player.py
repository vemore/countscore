"""Player model — global per group (one canonical entity per human player)."""

from __future__ import annotations

import unicodedata
import uuid
from collections.abc import Iterator
from datetime import UTC, datetime

from sqlalchemy import BigInteger, CheckConstraint, Column, DateTime, ForeignKey, Index
from sqlmodel import Field, SQLModel

from app.models._indexes import live_unique


def _utcnow() -> datetime:
    return datetime.now(UTC)


# Player name allow-list — prevents prompt injection via player names.
# Permits Unicode letters (each followed by any combining marks), numbers, spaces,
# hyphens, apostrophes, periods. Length 1-32 enforced separately (and by
# ck_player_name_length below).
#
# The marks are what make "रवि" (Devanagari vowel sign), "محمَّد" (Arabic harakat) or a
# decomposed "Nguyễn" a name: none of them is a letter on its own, so a mark is accepted
# only where it combines with one — never at the start, nor after a digit or a space.
#
# Kept as the written spec: ``\p{L}``/``\p{M}``/``\p{N}`` need the third-party ``regex``
# module, which we do not depend on, so ``is_valid_player_name`` implements the same rule
# with the stdlib. The app mirrors it (``lib/services/sync/sync_ids.dart``,
# ``isSyncablePlayerName``). Change all three together.
PLAYER_NAME_REGEX = r"^(?:\p{L}\p{M}*|\p{N}|[ \-'.])+$"

PLAYER_NAME_PUNCTUATION = frozenset(" -'.")
PLAYER_NAME_MAX_LENGTH = 32

_MARK_CATEGORIES = frozenset({"Mn", "Mc", "Me"})


def is_valid_player_name(name: str) -> bool:
    """The stdlib equivalent of PLAYER_NAME_REGEX, plus the 1-32 length bound.

    ``str.isalpha`` and ``str.isdigit`` are Unicode-aware, so accented and non-Latin
    names pass exactly as the regex intends.
    """
    if not 1 <= len(name) <= PLAYER_NAME_MAX_LENGTH:
        return False
    return all(kept for _, kept in _judged_chars(name))


def sanitize_player_name(name: str) -> str:
    """The same rule applied as a filter: drop what it refuses, then trim and clip.

    For paths that must not refuse a game over a name the app never validated locally
    (the ZapZap prompt). May return an empty string; the caller picks a fallback.
    """
    kept = "".join(c for c, ok in _judged_chars(name) if ok)
    return " ".join(kept.split())[:PLAYER_NAME_MAX_LENGTH].strip()


def _judged_chars(name: str) -> Iterator[tuple[str, bool]]:
    """Each character, with whether the rule accepts it where it stands.

    A mark is judged by what precedes it: accepted after a letter or after a mark that
    was itself accepted (stacked marks, as in "अँ"), refused anywhere else. A refused
    character breaks the chain, so a mark after a dropped emoji is dropped too.
    """
    after_letter = False
    for c in name:
        if unicodedata.category(c) in _MARK_CATEGORIES:
            yield c, after_letter
            continue
        after_letter = c.isalpha()
        yield c, after_letter or c.isdigit() or c in PLAYER_NAME_PUNCTUATION


class Player(SQLModel, table=True):
    __tablename__ = "players"
    __table_args__ = (
        Index("ix_players_group_id", "group_id"),
        live_unique("uq_players_group_name", "group_id", "name_normalized"),
        CheckConstraint("length(name) BETWEEN 1 AND 32", name="ck_player_name_length"),
    )

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    group_id: uuid.UUID = Field(
        sa_column=Column(ForeignKey("groups.id", ondelete="CASCADE"), nullable=False)
    )
    name: str = Field(max_length=32)
    # lower(trim(name)) — for the UNIQUE(group, name) constraint without imposing case sensitivity
    name_normalized: str = Field(max_length=32)
    color_value: int | None = Field(default=None, sa_column=Column(BigInteger, nullable=True))

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
