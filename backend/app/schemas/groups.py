"""Pydantic request/response schemas for the /groups endpoints."""

from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class CreateGroupRequest(BaseModel):
    name: str = Field(min_length=1, max_length=64)
    device_label: str = Field(default="default device", min_length=1, max_length=64)


class JoinGroupRequest(BaseModel):
    share_token: uuid.UUID
    device_label: str = Field(min_length=1, max_length=64)


class DevicePayload(BaseModel):
    id: uuid.UUID
    token: str  # raw token, returned ONCE at create/join
    label: str


class GroupPayload(BaseModel):
    """The group as any member device may read it — no share_token.

    Every device in a group is equal, so a token echoed on a routine read is a token
    every device can re-share at any time. It is returned only where the caller has
    explicitly asked for a share link: create, join, and rotate.
    """

    id: uuid.UUID
    name: str
    comment_style: str
    comment_language: str
    monthly_budget_cents: int
    current_month_used_cents: int


class GroupWithShareToken(GroupPayload):
    share_token: uuid.UUID


class CreateGroupResponse(BaseModel):
    group: GroupWithShareToken
    device: DevicePayload


class JoinGroupResponse(BaseModel):
    group: GroupWithShareToken
    device: DevicePayload


class UpdateGroupSettings(BaseModel):
    comment_style: str | None = Field(default=None, pattern="^(narrative|humorous|analytical)$")
    comment_language: str | None = Field(default=None, min_length=2, max_length=8)
    monthly_budget_cents: int | None = Field(default=None, ge=0, le=10_000)


class UsagePayload(BaseModel):
    current_month_used_cents: int
    budget_cents: int
    resets_at: datetime
