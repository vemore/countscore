"""Sliding-window rate limiter (per device) — see .llmwiki/LlmProviders.md.

Single source of truth: the ``rate_limits`` table. We use a windowed counter
(per-minute, per-hour, per-day) rather than a token bucket because the limits
are coarse and the operational picture is easier to reason about (we can SELECT
the table to see who is hot right now).
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.models import RateLimit


@dataclass(slots=True)
class RateLimitDecision:
    allowed: bool
    retry_after_seconds: int = 0
    scope: str = ""  # 'minute' | 'hour' | 'day'


async def check_and_increment(session: AsyncSession, device_id: uuid.UUID) -> RateLimitDecision:
    """Atomically check then increment counters. Returns whether the call may proceed.

    We do the read-modify-write inside the caller's transaction. On contention,
    Postgres serializes via row lock on the PK (device_id).
    """
    settings = get_settings()
    now = datetime.now(UTC)

    # Upsert a row, fetching the current state (initialized to zero on first call).
    stmt = pg_insert(RateLimit).values(
        device_id=device_id,
        minute_window_start=now,
        minute_count=0,
        hour_window_start=now,
        hour_count=0,
        day_window_start=now,
        day_count=0,
    )
    stmt = stmt.on_conflict_do_nothing(index_elements=["device_id"])
    await session.execute(stmt)

    rl = await session.get(RateLimit, device_id, with_for_update=True)
    if rl is None:  # pragma: no cover — defensive
        return RateLimitDecision(allowed=True)

    # Reset windows that have elapsed.
    if now - rl.minute_window_start >= timedelta(minutes=1):
        rl.minute_window_start = now
        rl.minute_count = 0
    if now - rl.hour_window_start >= timedelta(hours=1):
        rl.hour_window_start = now
        rl.hour_count = 0
    if now - rl.day_window_start >= timedelta(days=1):
        rl.day_window_start = now
        rl.day_count = 0

    # Check each window against its cap.
    if rl.minute_count >= settings.rl_per_minute:
        retry = 60 - int((now - rl.minute_window_start).total_seconds())
        return RateLimitDecision(False, max(1, retry), "minute")
    if rl.hour_count >= settings.rl_per_hour:
        retry = 3600 - int((now - rl.hour_window_start).total_seconds())
        return RateLimitDecision(False, max(1, retry), "hour")
    if rl.day_count >= settings.rl_per_day:
        retry = 86400 - int((now - rl.day_window_start).total_seconds())
        return RateLimitDecision(False, max(1, retry), "day")

    rl.minute_count += 1
    rl.hour_count += 1
    rl.day_count += 1
    return RateLimitDecision(allowed=True)
