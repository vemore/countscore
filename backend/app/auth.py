"""Device-token authentication.

A device token is ``<device id hex>.<secret>``, issued at create or join. We store only
the argon2 hash of the whole string. Each request carries it in
``Authorization: Bearer <token>``; the dependency resolves it to a Device + Group and
refuses revoked devices.

Why the device id travels in the token: it lets ``require_device`` fetch exactly one row
and run exactly one argon2 verify. The previous opaque token forced a verify against
every device in the database — about 30 ms each — for any bearer string, valid or not,
which made a junk-token request an unauthenticated CPU denial of service.

Why argon2 over a faster hash: the secret has high entropy (128 bits), so a fast hash
would be fine cryptographically, but argon2 makes brute-forcing a stolen DB dump
impractical at the cost of one verify per request.
"""

from __future__ import annotations

import secrets
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError
from fastapi import Depends, Header, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.db import get_session
from app.models import Device, Group
from app.services.ip_rate_limiter import check_ip_rate_limit, client_ip, is_exhausted

_hasher = PasswordHasher()
_AUTH_FAIL_BUCKET = "auth_fail"


def hash_token(raw: str) -> str:
    return _hasher.hash(raw)


def verify_token(raw: str, hashed: str) -> bool:
    try:
        _hasher.verify(hashed, raw)
        return True
    except (VerificationError, InvalidHashError):
        return False


def generate_token(device_id: uuid.UUID) -> str:
    """A fresh raw device token for ``device_id``: ``<id hex>.<32 hex chars of secret>``."""
    return f"{device_id.hex}.{secrets.token_hex(16)}"


def parse_token(raw: str) -> uuid.UUID | None:
    """The device id a token names, or None when the token is not of our shape."""
    device_hex, sep, secret = raw.partition(".")
    if not sep or not secret:
        return None
    try:
        return uuid.UUID(hex=device_hex)
    except ValueError:
        return None


@dataclass(slots=True)
class AuthContext:
    device: Device
    group: Group


def _unauthorized(detail: str) -> HTTPException:
    return HTTPException(status.HTTP_401_UNAUTHORIZED, detail)


async def require_device(
    request: Request,
    authorization: str | None = Header(default=None),
    session: AsyncSession = Depends(get_session),
) -> AuthContext:
    """FastAPI dependency: resolves ``Authorization: Bearer <token>`` to a Device + Group.

    At most one argon2 verify per request, and only while the caller's address is under
    the failed-check limit: once over it, the answer is a 429 before any hashing.
    """
    if not authorization or not authorization.lower().startswith("bearer "):
        raise _unauthorized("missing bearer token")
    raw = authorization.split(" ", 1)[1].strip()
    if not raw:
        raise _unauthorized("empty bearer token")

    device_id = parse_token(raw)
    if device_id is None:
        # Malformed: refused without touching the database or the hasher.
        raise _unauthorized("invalid or revoked device token")

    settings = get_settings()
    ip = client_ip(request)
    limits = {
        "per_minute": settings.auth_fail_rl_per_minute,
        "per_hour": settings.auth_fail_rl_per_hour,
    }
    if is_exhausted(ip, bucket=_AUTH_FAIL_BUCKET, **limits):
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, "too many failed token checks")

    device = await session.get(Device, device_id)
    if device is None or device.revoked_at is not None or not verify_token(raw, device.token_hash):
        check_ip_rate_limit(ip, bucket=_AUTH_FAIL_BUCKET, **limits)
        raise _unauthorized("invalid or revoked device token")

    group = await session.get(Group, device.group_id)
    if group is None:
        raise _unauthorized("orphaned device")
    device.last_seen_at = datetime.now(UTC)
    await session.commit()
    return AuthContext(device=device, group=group)
