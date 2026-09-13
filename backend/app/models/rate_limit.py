"""Sliding-window rate limit counters per device."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import Column, DateTime, ForeignKey
from sqlmodel import Field, SQLModel


def _utcnow() -> datetime:
    return datetime.now(UTC)


class RateLimit(SQLModel, table=True):
    __tablename__ = "rate_limits"

    device_id: uuid.UUID = Field(
        sa_column=Column(
            ForeignKey("devices.id", ondelete="CASCADE"), primary_key=True, nullable=False
        )
    )
    # Rolling counters (incremented atomically, reset by window boundaries)
    minute_window_start: datetime = Field(
        default_factory=_utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False),
    )
    minute_count: int = Field(default=0)
    hour_window_start: datetime = Field(
        default_factory=_utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False),
    )
    hour_count: int = Field(default=0)
    day_window_start: datetime = Field(
        default_factory=_utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False),
    )
    day_count: int = Field(default=0)
