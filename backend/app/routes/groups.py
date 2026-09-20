"""Group CRUD + device join/revoke endpoints.

A group has an owner (``Group.owner_device_id``): the device that created it, until it
hands the role over (``PUT /groups/me/owner``) or leaves. Only the owner may revoke a
sibling device, rotate the share token or set the monthly budget (it is spent on the
operator's key); every other member gets a 403. Leaving — a device revoking itself — and the
comment style and language stay open to every member, and an owner that leaves passes the
role to the earliest-joined live device, so a group with members always has an owner.

An owner that *uninstalls* sends no request at all, so none of that fires: the role would
sit for ever on a device that never comes back, and nobody could rotate the share token.
``Device.last_seen_at`` is what gives a way out — it is refreshed on every authenticated
request (``app/auth.py``). Past ``GROUP_OWNER_DORMANT_DAYS`` unseen, another member may take
the role deliberately (``POST /groups/me/owner/claim``, 409 while the owner is still about),
and a group down to a single live device simply owns itself, healed on read.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta

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
    TransferOwnershipRequest,
    UpdateGroupSettings,
    UsagePayload,
)
from app.services.budget import current_period
from app.services.ip_rate_limiter import check_ip_rate_limit, client_ip

router = APIRouter(prefix="/groups", tags=["groups"])


def _group_payload(g: Group) -> GroupPayload:
    used_cents, _ = current_period(g, datetime.now(UTC))
    return GroupPayload(
        id=g.id,
        name=g.name,
        owner_device_id=g.owner_device_id,
        comment_style=g.comment_style,
        comment_language=g.comment_language,
        monthly_budget_cents=g.monthly_budget_cents,
        current_month_used_cents=used_cents,
    )


def _group_payload_with_token(g: Group) -> GroupWithShareToken:
    return GroupWithShareToken(
        **_group_payload(g).model_dump(),
        share_token=g.share_token,
    )


async def _locked_group(session: AsyncSession, auth: AuthContext) -> Group:
    """The caller's group, row-locked and re-read, so a check on it holds until commit."""
    group = await session.get(Group, auth.group.id, with_for_update=True, populate_existing=True)
    assert group is not None
    return group


def _require_owner(group: Group, auth: AuthContext) -> None:
    if group.owner_device_id != auth.device.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "only the group owner may do this")


def _dormant_before(now: datetime) -> datetime:
    """A device unseen since this instant counts as dormant."""
    return now - timedelta(days=get_settings().group_owner_dormant_days)


def _is_dormant(last_seen_at: datetime, cutoff: datetime) -> bool:
    # SQLite hands back naive datetimes; they are stored as UTC.
    seen = last_seen_at if last_seen_at.tzinfo else last_seen_at.replace(tzinfo=UTC)
    return seen < cutoff


async def _owner_is_dormant(session: AsyncSession, group: Group, now: datetime) -> bool:
    """Whether the group's owner row has gone quiet long enough to be claimed.

    No owner, or an owner that was revoked, counts as dormant: there is nobody the claim
    could take the role from.
    """
    if group.owner_device_id is None:
        return True
    owner = await session.get(Device, group.owner_device_id)
    if owner is None or owner.revoked_at is not None:
        return True
    return _is_dormant(owner.last_seen_at, _dormant_before(now))


async def _sole_live_device(session: AsyncSession, group_id: uuid.UUID) -> uuid.UUID | None:
    """The group's only live device, or ``None`` when it has none or several."""
    rows = await session.execute(
        select(col(Device.id))
        .where(col(Device.group_id) == group_id, col(Device.revoked_at).is_(None))
        .limit(2)
    )
    ids = rows.scalars().all()
    return ids[0] if len(ids) == 1 else None


async def _heal_sole_device_owner(session: AsyncSession, auth: AuthContext) -> Group:
    """Give a group with a single live device back to it, on read.

    The degenerate dormant case: with one device left there is nothing to decide and
    nobody to take the role from, so it needs no claim and no window. Returns the group to
    answer with — the re-read row when it healed, the caller's own otherwise.
    """
    sole = await _sole_live_device(session, auth.group.id)
    if sole is None or sole == auth.group.owner_device_id:
        return auth.group
    group = await _locked_group(session, auth)
    sole = await _sole_live_device(session, group.id)  # re-read under the row lock
    if sole is None or group.owner_device_id == sole:
        return group
    group.owner_device_id = sole
    group.updated_at = datetime.now(UTC)
    await session.commit()
    await session.refresh(group)
    return group


async def _earliest_live_device(
    session: AsyncSession, group_id: uuid.UUID, excluding: uuid.UUID
) -> uuid.UUID | None:
    """The device an owner that leaves hands the group to: the one that joined first."""
    row = await session.execute(
        select(col(Device.id))
        .where(
            col(Device.group_id) == group_id,
            col(Device.revoked_at).is_(None),
            col(Device.id) != excluding,
        )
        .order_by(col(Device.joined_at), col(Device.id))
        .limit(1)
    )
    return row.scalar_one_or_none()


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
    group.owner_device_id = device.id
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
async def get_my_group(
    auth: AuthContext = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> GroupPayload:
    # This is where the app learns whether it is the owner, so it is where a group left
    # with one device is healed: the answer already names the right owner.
    return _group_payload(await _heal_sole_device_owner(session, auth))


@router.patch("/me/settings", response_model=GroupPayload)
async def update_settings(
    body: UpdateGroupSettings,
    auth: AuthContext = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> GroupPayload:
    group = await _locked_group(session, auth)
    if body.monthly_budget_cents is not None:
        # The budget is spent on the operator's key: the owner's alone, up to the operator's
        # cap. Style and language stay open to every member. A refused request changes nothing.
        _require_owner(group, auth)
        ceiling = get_settings().effective_max_budget_cents
        if body.monthly_budget_cents > ceiling:
            raise HTTPException(
                status.HTTP_422_UNPROCESSABLE_CONTENT,
                f"monthly_budget_cents is capped at {ceiling} by the operator",
            )
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
    # The stored counter is rolled over only when a comment is charged; a read applies the
    # same rule, so a past month's spending and a reset date in the past are never shown.
    used_cents, resets_at = current_period(auth.group, datetime.now(UTC))
    return UsagePayload(
        current_month_used_cents=used_cents,
        budget_cents=auth.group.monthly_budget_cents,
        resets_at=resets_at,
    )


@router.get("/me/devices", response_model=DeviceListResponse)
async def list_devices(
    auth: AuthContext = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> DeviceListResponse:
    """The group's active devices, oldest first — what a member needs to pick one to revoke.

    Revoked devices are left out: they cannot come back, and listing them would only offer
    a revoke that does nothing. ``dormant`` says the device has not been seen for
    ``GROUP_OWNER_DORMANT_DAYS``; on the owner's row it is what opens *Claim ownership*.
    """
    group = await _heal_sole_device_owner(session, auth)
    rows = await session.execute(
        select(Device)
        .where(col(Device.group_id) == group.id, col(Device.revoked_at).is_(None))
        .order_by(col(Device.joined_at), col(Device.id))
    )
    cutoff = _dormant_before(datetime.now(UTC))
    return DeviceListResponse(
        devices=[
            DeviceInfo(
                id=d.id,
                label=d.label,
                joined_at=d.joined_at,
                last_seen_at=d.last_seen_at,
                is_owner=d.id == group.owner_device_id,
                dormant=_is_dormant(d.last_seen_at, cutoff),
            )
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
    """Revoke a device. Revoking another one is the owner's, and rotates the share token.

    Every device learns the share token when it joins, so a revoke alone let the revoked
    device join again at once. The new token goes back to the caller only, as
    ``rotate-share-token`` does. A device revoking itself is leaving (the app's
    ``GroupProvider.leave``), open to every member: nothing to shut out, so no rotation
    and no token — 204. An owner that leaves hands the group to the earliest-joined
    device still live.
    """
    target = await session.get(Device, device_id)
    if target is None or target.group_id != auth.group.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "device not in this group")
    group = await _locked_group(session, auth)
    if target.id == auth.device.id:
        if target.revoked_at is None:
            target.revoked_at = datetime.now(UTC)
            if group.owner_device_id == target.id:
                group.owner_device_id = await _earliest_live_device(
                    session, group.id, excluding=target.id
                )
                group.updated_at = datetime.now(UTC)
            await session.commit()
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    _require_owner(group, auth)
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
    group = await _locked_group(session, auth)
    _require_owner(group, auth)
    group.share_token = uuid.uuid4()
    group.updated_at = datetime.now(UTC)
    await session.commit()
    await session.refresh(group)
    return _group_payload_with_token(group)


@router.put("/me/owner", response_model=GroupPayload)
async def transfer_ownership(
    body: TransferOwnershipRequest,
    auth: AuthContext = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> GroupPayload:
    """Hand the owner role to another live device of the group. The owner's only.

    Naming the owner itself is a no-op. The share token is not rotated and not returned:
    the new owner gets a fresh one the first time it rotates.
    """
    group = await _locked_group(session, auth)
    _require_owner(group, auth)
    target = await session.get(Device, body.device_id)
    if target is None or target.group_id != auth.group.id or target.revoked_at is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "device not in this group")
    if group.owner_device_id != target.id:
        group.owner_device_id = target.id
        group.updated_at = datetime.now(UTC)
        await session.commit()
        await session.refresh(group)
    return _group_payload(group)


@router.post(
    "/me/owner/claim",
    response_model=GroupPayload,
    responses={409: {"description": "The owner has been seen inside the dormancy window."}},
)
async def claim_ownership(
    auth: AuthContext = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> GroupPayload:
    """Take the owner role from an owner that has not been seen for the dormancy window.

    The way back for a group whose owner uninstalled the app: no request is ever sent then,
    so the role is stuck and the share token can never be rotated. It takes a deliberate act
    by a member rather than a clock, so a group decides for itself, and the former owner's
    reinstall is just one more device that may claim it back.

    **409** while the owner has been seen inside ``GROUP_OWNER_DORMANT_DAYS`` — the caller is
    a member with no special right, so the refusal must not be mistaken for a 403 on an
    owner-only route. Claiming what one already owns is a no-op, as ``PUT /me/owner`` is.
    Checked and changed under the group's row lock, so two claims cannot both pass.
    """
    group = await _locked_group(session, auth)
    if group.owner_device_id == auth.device.id:
        return _group_payload(group)
    if not await _owner_is_dormant(session, group, datetime.now(UTC)):
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "the group already has an owner that has been seen recently",
        )
    group.owner_device_id = auth.device.id
    group.updated_at = datetime.now(UTC)
    await session.commit()
    await session.refresh(group)
    return _group_payload(group)
