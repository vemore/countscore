# Any member of a group can change its analysis budget, style and language

- **Noted:** 2026-09-18 — while adding the group owner (`feat/group-owner`)
- **Theme:** groups-v2
- **Area:** backend
- **Blocks release:** no — capped by the operator's `MAX_BUDGET_CENTS`, and groups are a household today

`PATCH /groups/me/settings` (`backend/app/routes/groups.py`, `update_settings`) takes any
device token of the group. Since `0005_group_owner` a group has an owner that alone may revoke,
rotate and hand over, but the budget — the one setting that costs the operator money — is
still open to every member, up to `MAX_BUDGET_CENTS`. `.llmwiki/Security.md` lists it as what
stays open.

**Fix:** decide whether `monthly_budget_cents` (and possibly style and language) become
owner-only, and hide the control from other members in the app as the devices sheet does.

**Decided (2026-09-18, refinement 3):** the budget alone. `monthly_budget_cents` becomes
owner-only (it costs the operator money); comment style and language stay open to every member.

**Acceptance:**
- `PATCH /groups/me/settings` with `monthly_budget_cents` from a non-owner device answers 403; from the owner it succeeds (backend test).
- A non-owner can still change `comment_style` and `comment_language`.
- `.llmwiki/Security.md` no longer lists the budget as open to every member.
