# A device restored from a backup never gets its own later edits back

**Status:** done (2026-11-25) — closed by fix/restored-device-own-deltas. `SyncStore._applyOne` skips an own delta only when the database holds it (`_holdsOwn`): `entity_versions` has its version or a later one of this device's (recorded on `applied`, `duplicate` and now `merged_lww`, which the server logs too), or this group's outbox holds the same delta unsent (in flight, its answer lost). A pulled game upsert on a game held locally moves it and its rows into the group. Any other own delta is applied like another device's — the first fix below, with the outbox test added for the lost answer; no restore flag, which an auto-backup restore could not set (`.llmwiki/Sync.md`, *Decisions & History*). Tested through a real server (`sync_multi_group_backend_test.dart`, *a restored database*) and in `sync_store_test.dart`.

- **Noted:** 2026-11-25 — feat/multi-group-sync-sessions, testing `lamport_reused` through a real server
- **Theme:** sync-robustness
- **Area:** app
- **Blocks release:** no

A database restored from a backup (or imported through Settings → Import) brings back its
`sync_state` row: the cursor and the clock of the moment it was taken. The next pull returns
everything logged since, this device's own deltas included — the edits it pushed between
the backup and the restore. `SyncStore._applyOne` skips every delta whose
`origin_device_id` is this device's (`lib/services/sync/sync_store.dart`): it records the
version and applies nothing, on the assumption that the device already holds what it sent.
After a restore it does not. Those edits stay on the server and on every other device, and
this one keeps the older rows until someone edits them again — a silent divergence, and the
next local edit of such a row pushes the old values back over the group's (it carries a
newer lamport).

**Fix (to weigh):** apply an own delta when the local row's version is older than it —
`entity_versions` holds what this device last knew, and a restored database holds an older
version than the log — instead of skipping own deltas unconditionally. Or mark a restore
(an import already reconciles memberships, `sync_reconcile.dart`) and let the first pull
after it apply own deltas too.

**Acceptance:**
- Through a real server: a device pushes an edit, its database goes back to a copy taken
  before it (cursor and clock), the next pass restores the edit locally, and the next local
  edit of that row does not undo it on the other devices.
