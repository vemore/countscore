"""Pydantic schemas for sync endpoints."""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, Field

EntityType = Literal[
    "player", "game_type", "game", "game_player", "round", "score"
]
DeltaOp = Literal["upsert", "delete"]
DeltaStatus = Literal["applied", "merged_lww", "rejected", "duplicate"]


class DeltaIn(BaseModel):
    entity_type: EntityType
    entity_uuid: uuid.UUID
    op: DeltaOp
    payload: dict[str, Any] = Field(default_factory=dict)
    client_lamport: int = Field(ge=0)


class DeltaOut(BaseModel):
    entity_type: EntityType
    entity_uuid: uuid.UUID
    op: DeltaOp
    payload: dict[str, Any]
    client_lamport: int
    origin_device_id: uuid.UUID
    server_seq: int
    applied_at: datetime


class DeltaResult(BaseModel):
    delta_idx: int
    status: DeltaStatus
    server_seq: int | None = None
    reason: str | None = None


class PushRequest(BaseModel):
    deltas: list[DeltaIn] = Field(default_factory=list, max_length=500)


class PushResponse(BaseModel):
    results: list[DeltaResult]
    server_seq_max: int


class PullResponse(BaseModel):
    deltas: list[DeltaOut]
    server_seq_max: int
    has_more: bool


class WsTicketResponse(BaseModel):
    """A single-use credential for the /sync/stream handshake."""

    ticket: str
    expires_in: int
