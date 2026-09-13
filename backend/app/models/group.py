"""Group model — a synchronization scope."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import Column, DateTime, Index
from sqlmodel import Field, SQLModel


def _utcnow() -> datetime:
    return datetime.now(UTC)


class Group(SQLModel, table=True):
    __tablename__ = "groups"
    __table_args__ = (Index("ix_groups_share_token", "share_token", unique=True),)

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    name: str = Field(max_length=64)
    share_token: uuid.UUID = Field(default_factory=uuid.uuid4)

    # Comment generation settings
    comment_style: str = Field(default="narrative", max_length=16)
    comment_language: str = Field(default="fr", max_length=8)
    monthly_budget_cents: int = Field(default=100)
    current_month_used_cents: int = Field(default=0)
    budget_resets_at: datetime = Field(
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
