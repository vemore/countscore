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

**Open question:** owner-only for the budget alone, or for every group setting?
