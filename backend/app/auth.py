"""Device-token authentication.

Devices receive a random UUID v4 token at join time. We store only its argon2 hash.
Each request carries the raw token in ``Authorization: Bearer <token>``; the middleware
resolves it to a Device + Group, refuses revoked devices.

Why argon2 over a faster hash: device_tokens are bearer credentials with high entropy
(122 bits) — a fast hash would be fine cryptographically, but argon2 makes brute-forcing
a stolen DB dump impractical without measurable cost at request time (one verify ≈ 30ms
with default params; we can tune ``time_cost`` if it becomes a bottleneck).
"""
from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import datetime, timezone

from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
from fastapi import Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_session
from app.models import Device, Group

_hasher = PasswordHasher()


def hash_token(raw: str) -> str:
    return _hasher.hash(raw)


def verify_token(raw: str, hashed: str) -> bool:
    try:
        _hasher.verify(hashed, raw)
        return True
    except VerifyMismatchError:
        return False


def generate_token() -> str:
    """Returns a fresh raw device_token (uuid v4 hex)."""
    return uuid.uuid4().hex


@dataclass(slots=True)
class AuthContext:
    device: Device
    group: Group


async def require_device(
    authorization: str | None = Header(default=None),
    session: AsyncSession = Depends(get_session),
) -> AuthContext:
    """FastAPI dependency: resolves ``Authorization: Bearer <token>`` to a Device + Group.

    Cost note: this performs N argon2 verifications where N is the number of devices in DB.
    For early scale (<1000 devices) this is fine (<1s). Optimization path if needed:
    store a short keyed prefix of the raw token alongside the hash and index it, so we
    only argon2-verify the candidate rows.
    """
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "missing bearer token")
    raw = authorization.split(" ", 1)[1].strip()
    if not raw:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "empty bearer token")

    # Try each non-revoked device. With argon2, this is intentionally slow;
    # see the docstring above for the optimization path.
    result = await session.execute(select(Device).where(Device.revoked_at.is_(None)))
    devices = result.scalars().all()
    for device in devices:
        if verify_token(raw, device.token_hash):
            group = await session.get(Group, device.group_id)
            if group is None:
                raise HTTPException(status.HTTP_401_UNAUTHORIZED, "orphaned device")
            device.last_seen_at = datetime.now(timezone.utc)
            await session.commit()
            return AuthContext(device=device, group=group)
    raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid or revoked device token")
