"""Per-group monthly budget enforcement.

The budget is a *soft* cap: the pre-call check uses an estimate (~0.12¢ per Haiku
comment), and we charge the actual cost after the call returns. So a group might
slightly exceed its budget on the call that crosses the threshold, but never by
more than one comment's worth.

Reset: a monthly cron (or simply a check on each call) rolls the counter to 0
when ``budget_resets_at`` has passed.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import UTC, datetime

from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Group

ESTIMATED_COMMENT_COST_CENTS = 1  # conservative; actual is closer to ~0.1¢


@dataclass(slots=True)
class BudgetDecision:
    allowed: bool
    used_cents: int = 0
    budget_cents: int = 0
    resets_at: datetime | None = None


def _next_month_start(now: datetime) -> datetime:
    if now.month == 12:
        return datetime(now.year + 1, 1, 1, tzinfo=UTC)
    return datetime(now.year, now.month + 1, 1, tzinfo=UTC)


async def check_budget(session: AsyncSession, group_id: uuid.UUID) -> BudgetDecision:
    """Returns whether a comment generation is within budget. Caller must hold a tx."""
    group = await session.get(Group, group_id, with_for_update=True)
    if group is None:
        return BudgetDecision(allowed=False)

    now = datetime.now(UTC)
    if group.budget_resets_at <= now:
        group.current_month_used_cents = 0
        group.budget_resets_at = _next_month_start(now)

    if group.current_month_used_cents + ESTIMATED_COMMENT_COST_CENTS > group.monthly_budget_cents:
        return BudgetDecision(
            allowed=False,
            used_cents=group.current_month_used_cents,
            budget_cents=group.monthly_budget_cents,
            resets_at=group.budget_resets_at,
        )

    return BudgetDecision(
        allowed=True,
        used_cents=group.current_month_used_cents,
        budget_cents=group.monthly_budget_cents,
        resets_at=group.budget_resets_at,
    )


async def charge_budget(session: AsyncSession, group_id: uuid.UUID, actual_cost_cents: int) -> None:
    """Increments the group's used_cents by the actual cost. Caller holds the tx."""
    group = await session.get(Group, group_id, with_for_update=True)
    if group is None:  # pragma: no cover — defensive
        return
    group.current_month_used_cents += actual_cost_cents
