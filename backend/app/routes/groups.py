"""Group CRUD + device join/revoke endpoints."""
from __future__ import annotations

import uuid
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col

from app.auth import AuthContext, generate_token, hash_token, require_device
from app.config import get_settings
from app.db import get_session
from app.models import Device, Group
from app.schemas.groups import (
    CreateGroupRequest,
    CreateGroupResponse,
    DevicePayload,
    GroupPayload,
    GroupWithShareToken,
    JoinGroupRequest,
    JoinGroupResponse,
    UpdateGroupSettings,
    UsagePayload,
)
from app.services.ip_rate_limiter import check_ip_rate_limit, client_ip

router = APIRouter(prefix="/groups", tags=["groups"])


def _group_payload(g: Group) -> GroupPayload:
    return GroupPayload(
        id=g.id,
        name=g.name,
        comment_style=g.comment_style,
        comment_language=g.comment_language,
        monthly_budget_cents=g.monthly_budget_cents,
        current_month_used_cents=g.current_month_used_cents,
    )


def _group_payload_with_token(g: Group) -> GroupWithShareToken:
    return GroupWithShareToken(
        **_group_payload(g).model_dump(),
        share_token=g.share_token,
    )


def _enforce_group_rate_limit(request: Request, response: Response) -> None:
    """Per-IP throttle on the two unauthenticated group endpoints.

    Creating a group is free and inserts a Device row, and every Device row makes the
    O(N) argon2 scan in ``require_device`` slower for everyone — so create spam degrades
    latency service-wide, not just storage. On ``/join`` the same limit is what stops a
    caller from grinding share_tokens: a 201 and a 404 tell valid from invalid.
    """
    settings = get_settings()
    dec = check_ip_rate_limit(
        client_ip(request),
        bucket="groups",
        per_minute=settings.group_rl_per_minute,
        per_hour=settings.group_rl_per_hour,
    )
    if not dec.allowed:
        response.headers["Retry-After"] = str(dec.retry_after_seconds)
        raise HTTPException(
            status.HTTP_429_TOO_MANY_REQUESTS,
            f"rate-limited at {dec.scope} scope",
            headers={"Retry-After": str(dec.retry_after_seconds)},
        )


@router.post("", response_model=CreateGroupResponse, status_code=status.HTTP_201_CREATED)
async def create_group(
    body: CreateGroupRequest,
    request: Request,
    response: Response,
    session: AsyncSession = Depends(get_session),
) -> CreateGroupResponse:
    _enforce_group_rate_limit(request, response)
    settings = get_settings()
    group = Group(
        name=body.name,
        monthly_budget_cents=settings.default_budget_cents,
    )
    session.add(group)
    await session.flush()

    raw_token = generate_token()
    device = Device(
        group_id=group.id,
        token_hash=hash_token(raw_token),
        label=body.device_label,
    )
    session.add(device)
    await session.commit()
    await session.refresh(group)
    await session.refresh(device)

    return CreateGroupResponse(
        group=_group_payload_with_token(group),
        device=DevicePayload(id=device.id, token=raw_token, label=device.label),
    )


@router.post("/join", response_model=JoinGroupResponse, status_code=status.HTTP_201_CREATED)
async def join_group(
    body: JoinGroupRequest,
    request: Request,
    response: Response,
    session: AsyncSession = Depends(get_session),
) -> JoinGroupResponse:
    _enforce_group_rate_limit(request, response)
    result = await session.execute(select(Group).where(col(Group.share_token) == body.share_token))
    group = result.scalar_one_or_none()
    if group is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "unknown share token")

    raw_token = generate_token()
    device = Device(
        group_id=group.id,
        token_hash=hash_token(raw_token),
        label=body.device_label,
    )
    session.add(device)
    await session.commit()
    await session.refresh(device)

    return JoinGroupResponse(
        group=_group_payload_with_token(group),
        device=DevicePayload(id=device.id, token=raw_token, label=device.label),
    )


@router.get("/me", response_model=GroupPayload)
async def get_my_group(auth: AuthContext = Depends(require_device)) -> GroupPayload:
    return _group_payload(auth.group)


@router.patch("/me/settings", response_model=GroupPayload)
async def update_settings(
    body: UpdateGroupSettings,
    auth: AuthContext = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> GroupPayload:
    group = await session.get(Group, auth.group.id, with_for_update=True)
    assert group is not None
    if body.comment_style is not None:
        group.comment_style = body.comment_style
    if body.comment_language is not None:
        group.comment_language = body.comment_language
    if body.monthly_budget_cents is not None:
        group.monthly_budget_cents = body.monthly_budget_cents
    group.updated_at = datetime.now(UTC)
    await session.commit()
    await session.refresh(group)
    return _group_payload(group)


@router.get("/me/usage", response_model=UsagePayload)
async def get_usage(auth: AuthContext = Depends(require_device)) -> UsagePayload:
    return UsagePayload(
        current_month_used_cents=auth.group.current_month_used_cents,
        budget_cents=auth.group.monthly_budget_cents,
        resets_at=auth.group.budget_resets_at,
    )


@router.post("/me/devices/{device_id}/revoke", status_code=status.HTTP_204_NO_CONTENT)
async def revoke_device(
    device_id: uuid.UUID,
    auth: AuthContext = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> None:
    target = await session.get(Device, device_id)
    if target is None or target.group_id != auth.group.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "device not in this group")
    if target.revoked_at is not None:
        return
    target.revoked_at = datetime.now(UTC)
    await session.commit()


@router.post("/me/rotate-share-token", response_model=GroupWithShareToken)
async def rotate_share_token(
    auth: AuthContext = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> GroupWithShareToken:
    group = await session.get(Group, auth.group.id, with_for_update=True)
    assert group is not None
    group.share_token = uuid.uuid4()
    group.updated_at = datetime.now(UTC)
    await session.commit()
    await session.refresh(group)
    return _group_payload_with_token(group)
