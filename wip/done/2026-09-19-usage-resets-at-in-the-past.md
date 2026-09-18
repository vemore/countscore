# GET /groups/me/usage reports a reset date in the past

**Status:** done (2026-09-19) — closed by fix/usage-resets-at-in-the-past. `budget.current_period` is the one roll-over rule, applied by `check_budget` (persisted) and by `GET /me/usage` and `GET /me` (read-only); a new group's `budget_resets_at` defaults to the next month start (Python-side default, no migration).

- **Noted:** 2026-09-19 — smoke-testing production after #120 (Settings → Group → Comments and usage)
- **Theme:** groups-v2
- **Area:** backend
- **Blocks release:** no

A freshly created group answers `GET /groups/me/usage` with `resets_at` equal to its creation
time (e.g. `2026-09-18T22:34:05Z`), not the start of next month. `Group.budget_resets_at`
(`backend/app/models/group.py`) defaults to `_utcnow`, and only `check_budget`
(`backend/app/services/budget.py`) rolls it forward to the next month start, when a comment is
charged. `get_usage` (`backend/app/routes/groups.py`) returns the stored value raw — and with it
a `current_month_used_cents` that may belong to a previous month. The app never triggers a
charge today, so its usage screen shows a past reset date.

**Fix:** one pure roll-over rule in `budget.py`, applied by both the charge path and the reads
(`/me/usage`, and `current_month_used_cents` in `GET /me`); a new group starts with
`budget_resets_at` at the next month start.

**Acceptance:**
- A new group's `GET /groups/me/usage` has `resets_at` in the future, at a month start.
- A group whose `budget_resets_at` has passed reports `current_month_used_cents: 0` and the
  next month start.
