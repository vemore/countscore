"""Pydantic request/response schemas for the /groups endpoints."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Annotated

from pydantic import BaseModel, Field, StringConstraints

# A device's name in its group, as its siblings see it. Surrounding whitespace is dropped
# before the length is checked, so a blank label is a 422 rather than an invisible name.
DeviceLabel = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=64)]


class CreateGroupRequest(BaseModel):
    name: str = Field(min_length=1, max_length=64)
    device_label: str = Field(default="default device", min_length=1, max_length=64)


class JoinGroupRequest(BaseModel):
    share_token: uuid.UUID
    device_label: str = Field(min_length=1, max_length=64)


class RenameDeviceRequest(BaseModel):
    label: DeviceLabel


class RenamedDevice(BaseModel):
    """The caller's device after a rename: its id and the label now stored."""

    id: uuid.UUID
    label: str


class DevicePayload(BaseModel):
    id: uuid.UUID
    token: str  # raw token, returned ONCE at create/join
    label: str


class DeviceInfo(BaseModel):
    """A member device as its siblings see it: enough to recognise a lost phone, no token.

    ``dormant`` is ``last_seen_at`` older than ``GROUP_OWNER_DORMANT_DAYS``. It is stated
    per device rather than once for the group because it is meaningful on any row; the app
    only reads it on the owner's, where it is what opens *Claim ownership*.
    """

    id: uuid.UUID
    label: str
    joined_at: datetime
    last_seen_at: datetime
    is_owner: bool
    dormant: bool


class DeviceListResponse(BaseModel):
    devices: list[DeviceInfo]


class GroupPayload(BaseModel):
    """The group as any member device may read it — no share_token.

    A token echoed on a routine read is a token every device can re-share at any time.
    It is returned only where the caller has explicitly asked for a share link: create,
    join, rotate, and the owner's revoke.

    ``owner_device_id`` is how a member learns whether it is the owner — the device that
    may revoke a sibling, rotate the share token and hand the role over. The app compares
    it with its own device id; nothing is stored on the device.
    """

    id: uuid.UUID
    name: str
    owner_device_id: uuid.UUID | None
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


class TransferOwnershipRequest(BaseModel):
    device_id: uuid.UUID


class UpdateGroupSettings(BaseModel):
    comment_style: str | None = Field(default=None, pattern="^(narrative|humorous|analytical)$")
    comment_language: str | None = Field(default=None, min_length=2, max_length=8)
    monthly_budget_cents: int | None = Field(default=None, ge=0, le=10_000)


class UsagePayload(BaseModel):
    current_month_used_cents: int
    budget_cents: int
    resets_at: datetime
