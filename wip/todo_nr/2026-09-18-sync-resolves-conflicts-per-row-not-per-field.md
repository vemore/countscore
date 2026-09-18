# Sync resolves concurrent edits per row, so one edit loses whole

- **Noted:** 2026-09-18 — split out of `2026-09-13-group-settings-in-app` during refinement
- **Theme:** groups-v2
- **Area:** backend
- **Blocks release:** no

`.llmwiki/Sync.md`: the server resolves conflicts **per row**. `backend/app/routes/sync.py`
compares the incoming `(client_lamport, origin_device_id)` with the highest pair in
`change_log` for the entity, and drops a losing delta whole (`merged_lww`); per-field would
need a `field_versions` table, and there is none. Two devices editing *different* fields of
the same game at the same time lose one of the two edits.

**Fix:** to be designed — a `field_versions` table and a per-field comparison on the server,
and the matching contract on the client (`db-migration` skill, [[Sync]]). Probably more than
one pull request: split before promotion.

