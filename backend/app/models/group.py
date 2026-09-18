"""Group model — a synchronization scope."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import BigInteger, Column, DateTime, Index
from sqlmodel import Field, SQLModel


def _utcnow() -> datetime:
    return datetime.now(UTC)


class Group(SQLModel, table=True):
    __tablename__ = "groups"
    __table_args__ = (Index("ix_groups_share_token", "share_token", unique=True),)

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    name: str = Field(max_length=64)
    share_token: uuid.UUID = Field(default_factory=uuid.uuid4)

    # The device allowed to revoke a sibling, rotate the share token and hand this role on:
    # the device that created the group, until it hands over or leaves. No foreign key —
    # devices and groups would reference each other, and a device row is never deleted
    # except with its group. Null only for a group none of whose devices is live.
    owner_device_id: uuid.UUID | None = Field(default=None)

    # The last server_seq handed out in this group. Read under a row lock at the start of
    # every push, so two concurrent pushes cannot mint the same sequence number.
    last_server_seq: int = Field(
        default=0, sa_column=Column(BigInteger, nullable=False, server_default="0")
    )

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
