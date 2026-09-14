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
    DeviceInfo,
    DeviceListResponse,
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

    Creating a group is free and inserts a Device row, so create spam costs storage. On
    ``/join`` the same limit is what stops a caller from grinding share_tokens: a 201 and
    a 404 tell valid from invalid.
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

    device_id = uuid.uuid4()
    raw_token = generate_token(device_id)
    device = Device(
        id=device_id,
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

    device_id = uuid.uuid4()
    raw_token = generate_token(device_id)
    device = Device(
        id=device_id,
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
    ceiling = get_settings().effective_max_budget_cents
    if body.monthly_budget_cents is not None and body.monthly_budget_cents > ceiling:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_CONTENT,
            f"monthly_budget_cents is capped at {ceiling} by the operator",
        )
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


@router.get("/me/devices", response_model=DeviceListResponse)
async def list_devices(
    auth: AuthContext = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> DeviceListResponse:
    """The group's active devices, oldest first — what a member needs to pick one to revoke.

    Revoked devices are left out: they cannot come back, and listing them would only offer
    a revoke that does nothing.
    """
    rows = await session.execute(
        select(Device)
        .where(col(Device.group_id) == auth.group.id, col(Device.revoked_at).is_(None))
        .order_by(col(Device.joined_at), col(Device.id))
    )
    return DeviceListResponse(
        devices=[
            DeviceInfo(id=d.id, label=d.label, joined_at=d.joined_at, last_seen_at=d.last_seen_at)
            for d in rows.scalars()
        ]
    )


@router.post(
    "/me/devices/{device_id}/revoke",
    response_model=GroupWithShareToken,
    responses={204: {"description": "The caller revoked itself: it left the group."}},
)
async def revoke_device(
    device_id: uuid.UUID,
    auth: AuthContext = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> GroupWithShareToken | Response:
    """Revoke a device. Revoking another one also rotates the share token.

    Every device learns the share token when it joins, so a revoke alone let the revoked
    device join again at once. The new token goes back to the caller only, as
    ``rotate-share-token`` does. A device revoking itself is leaving (the app's
    ``GroupProvider.leave``): nothing to shut out, so no rotation and no token — 204.
    """
    target = await session.get(Device, device_id)
    if target is None or target.group_id != auth.group.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "device not in this group")
    if target.id == auth.device.id:
        if target.revoked_at is None:
            target.revoked_at = datetime.now(UTC)
            await session.commit()
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    group = await session.get(Group, auth.group.id, with_for_update=True)
    assert group is not None
    # Already revoked: its token was rotated then, so the current one is safe to return.
    if target.revoked_at is None:
        now = datetime.now(UTC)
        target.revoked_at = now
        group.share_token = uuid.uuid4()
        group.updated_at = now
        await session.commit()
        await session.refresh(group)
    return _group_payload_with_token(group)


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
