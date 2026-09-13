"""Single-use, short-lived tickets for the /sync/stream WebSocket handshake.

Browsers cannot set headers on a WebSocket handshake, so the credential has to travel
in the URL. Sending the long-lived ``device_token`` there puts a bearer credential into
proxy access logs and browser history. Instead a device exchanges its token — over a
normal authenticated request, where the header works — for a ticket that is valid once
and for ``TICKET_TTL_SECONDS``.

State is process-local, exactly like ``app.services.ip_rate_limiter``: the production
deploy runs a single uvicorn worker (see docker-compose.prod.yml), so a ticket issued by
the worker is redeemable by that same worker. Do not raise the worker count without
moving this state out of memory first.
"""

from __future__ import annotations

import secrets
import time
import uuid
from dataclasses import dataclass

TICKET_TTL_SECONDS = 60


@dataclass(slots=True)
class _Ticket:
    device_id: uuid.UUID
    group_id: uuid.UUID
    expires_at: float


_tickets: dict[str, _Ticket] = {}


def reset() -> None:
    """Clear every outstanding ticket — used by tests."""
    _tickets.clear()


def _sweep(now: float) -> None:
    """Drop expired tickets. Cheap: the dict only holds live handshakes."""
    for key in [k for k, t in _tickets.items() if t.expires_at <= now]:
        del _tickets[key]


def issue(device_id: uuid.UUID, group_id: uuid.UUID) -> str:
    """Mint a ticket for a device that has already proven its identity."""
    now = time.monotonic()
    _sweep(now)
    ticket = secrets.token_urlsafe(32)
    _tickets[ticket] = _Ticket(
        device_id=device_id,
        group_id=group_id,
        expires_at=now + TICKET_TTL_SECONDS,
    )
    return ticket


def consume(ticket: str) -> tuple[uuid.UUID, uuid.UUID] | None:
    """Redeem a ticket, returning ``(device_id, group_id)`` or None.

    The ticket is removed whether or not it had expired, so a leaked ticket cannot be
    replayed even within its TTL.
    """
    if not ticket:
        return None
    now = time.monotonic()
    entry = _tickets.pop(ticket, None)
    if entry is None or entry.expires_at <= now:
        return None
    return entry.device_id, entry.group_id
