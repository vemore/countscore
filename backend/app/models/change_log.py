"""Append-only change log — the source of truth for the delta-log sync."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import JSON, Column, DateTime, ForeignKey, Index
from sqlalchemy.dialects.postgresql import JSONB
from sqlmodel import Field, SQLModel

# Use JSONB on Postgres (better indexing, jsonb ops) and JSON on SQLite (tests).
_JSON_TYPE = JSON().with_variant(JSONB(), "postgresql")


def _utcnow() -> datetime:
    return datetime.now(UTC)


class ChangeLog(SQLModel, table=True):
    __tablename__ = "change_log"
    __table_args__ = (
        Index("ix_change_log_group_seq", "group_id", "server_seq"),
        Index("ix_change_log_dedup", "origin_device_id", "client_lamport", unique=True),
        Index("ix_change_log_entity", "entity_type", "entity_uuid", "client_lamport"),
    )

    id: int | None = Field(default=None, primary_key=True)
    group_id: uuid.UUID = Field(
        sa_column=Column(ForeignKey("groups.id", ondelete="CASCADE"), nullable=False)
    )
    origin_device_id: uuid.UUID = Field(
        sa_column=Column(ForeignKey("devices.id", ondelete="CASCADE"), nullable=False)
    )
    entity_type: str = Field(max_length=32)
    entity_uuid: uuid.UUID
    op: str = Field(max_length=8)  # 'upsert' | 'delete'
    payload: dict[str, Any] = Field(
        default_factory=dict, sa_column=Column(_JSON_TYPE, nullable=False)
    )
    client_lamport: int
    server_seq: int = Field(index=True)
    applied_at: datetime = Field(
        default_factory=_utcnow,
        sa_column=Column(DateTime(timezone=True), nullable=False),
    )
