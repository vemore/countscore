"""In-memory per-IP rate limiter for the unauthenticated LLM endpoints.

The DB-backed ``rate_limits`` table is keyed by ``device_id`` (FK to devices), so it
cannot track anonymous callers. ``/comments/mvp`` and ``/comments/zapzap-analysis`` call
paid LLM APIs, so we cap calls per client IP to bound cost-abuse once public.

State is process-local: the production deploy runs a single uvicorn worker
(see docker-compose.prod.yml) so the window is authoritative. Behind Synology Web Station
the real client address arrives in ``X-Forwarded-For``.
"""
from __future__ import annotations

import time
from dataclasses import dataclass

from fastapi import Request

from app.config import get_settings
from app.services.rate_limiter import RateLimitDecision


@dataclass(slots=True)
class _Window:
    minute_start: float
    minute_count: int
    hour_start: float
    hour_count: int


_buckets: dict[str, _Window] = {}
_last_sweep = 0.0


def client_ip(request: Request) -> str:
    """Real client IP: first hop of X-Forwarded-For, else the socket peer."""
    fwd = request.headers.get("x-forwarded-for")
    if fwd:
        return fwd.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


def reset() -> None:
    """Clear all buckets — used by tests."""
    _buckets.clear()
    global _last_sweep
    _last_sweep = 0.0


def _sweep(now: float) -> None:
    """Evict IPs whose hour window has fully elapsed, to bound memory."""
    global _last_sweep
    if now - _last_sweep < 3600:
        return
    _last_sweep = now
    stale = [ip for ip, w in _buckets.items() if now - w.hour_start >= 3600]
    for ip in stale:
        del _buckets[ip]


def check_ip_rate_limit(ip: str) -> RateLimitDecision:
    settings = get_settings()
    now = time.monotonic()
    _sweep(now)

    w = _buckets.get(ip)
    if w is None:
        w = _Window(minute_start=now, minute_count=0, hour_start=now, hour_count=0)
        _buckets[ip] = w

    if now - w.minute_start >= 60:
        w.minute_start = now
        w.minute_count = 0
    if now - w.hour_start >= 3600:
        w.hour_start = now
        w.hour_count = 0

    if w.minute_count >= settings.ip_rl_per_minute:
        return RateLimitDecision(False, max(1, 60 - int(now - w.minute_start)), "minute")
    if w.hour_count >= settings.ip_rl_per_hour:
        return RateLimitDecision(False, max(1, 3600 - int(now - w.hour_start)), "hour")

    w.minute_count += 1
    w.hour_count += 1
    return RateLimitDecision(allowed=True)
