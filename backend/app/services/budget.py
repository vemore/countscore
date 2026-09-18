"""Per-group monthly budget enforcement.

The budget is a *soft* cap: the pre-call check uses an estimate (~0.12¢ per Haiku
comment), and we charge the actual cost after the call returns. So a group might
slightly exceed its budget on the call that crosses the threshold, but never by
more than one comment's worth.

Reset: ``current_period`` is the one roll-over rule — once ``budget_resets_at`` has passed,
the counter is 0 and the period ends at the next month start. ``check_budget`` persists it on
each charge; the usage reads apply it without writing.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import UTC, datetime

from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Group
from app.models.group import next_month_start

ESTIMATED_COMMENT_COST_CENTS = 1  # conservative; actual is closer to ~0.1¢


@dataclass(slots=True)
class BudgetDecision:
    allowed: bool
    used_cents: int = 0
    budget_cents: int = 0
    resets_at: datetime | None = None


def current_period(group: Group, now: datetime) -> tuple[int, datetime]:
    """``(used_cents, resets_at)`` as they stand at ``now``, without writing anything.

    Once ``budget_resets_at`` has passed, the stored counter belongs to an earlier month: the
    period is a fresh one, nothing spent, ending at the next month start. ``check_budget``
    persists that roll-over when a comment is charged; the reads (``GET /groups/me/usage``,
    ``GET /groups/me``) report it without taking the group lock.
    """
    resets_at = group.budget_resets_at
    if resets_at.tzinfo is None:  # SQLite hands back naive datetimes; they are stored as UTC
        resets_at = resets_at.replace(tzinfo=UTC)
    if resets_at <= now:
        return 0, next_month_start(now)
    return group.current_month_used_cents, resets_at


async def check_budget(session: AsyncSession, group_id: uuid.UUID) -> BudgetDecision:
    """Returns whether a comment generation is within budget. Caller must hold a tx."""
    group = await session.get(Group, group_id, with_for_update=True)
    if group is None:
        return BudgetDecision(allowed=False)

    # Persist the roll-over, if any, under the lock the charge that follows relies on.
    group.current_month_used_cents, group.budget_resets_at = current_period(
        group, datetime.now(UTC)
    )

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
