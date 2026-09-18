# The app has no screen for the group settings or the LLM usage

- **Noted:** 2026-09-13 — out of scope for the sync client, decided with the user; the device list and revoke half shipped 2026-09-14
- **Theme:** groups-v2
- **Area:** app
- **Blocks release:** no

The app calls `GET /groups/me` only for the owner (#104), and does not use `PATCH /groups/me/settings` (comment style, language,
LLM budget) or `GET /groups/me/usage`. The budget control is shown to the owner only
([[2026-09-18-group-settings-open-to-every-member]]). Since #76 the voice is chosen for each analysis and the
group style is only its fallback, but the user still wants the group's comment style and
language editable, and the usage visible.

**Split (2026-09-18, refinement):** this was an umbrella entry. Per-field LWW is now
[[2026-09-18-sync-resolves-conflicts-per-row-not-per-field]], and the owner role
[[2026-09-18-no-owner-role-in-a-group]]. This entry keeps only the settings and usage screen.

**Fix:** a group settings screen under Settings → Group: comment style and language read from
`GET /groups/me` and written with `PATCH /groups/me/settings`, and the LLM usage from
`GET /groups/me/usage`. Every string through `AppLocalizations`; nothing is called while no
server URL is set.

**Acceptance:**
- The group's comment style and language are shown and edited from the app, and the change survives a restart.
- The usage from `GET /groups/me/usage` is shown.
- Strings exist in the ten ARB files, and no request is made without a server URL.
