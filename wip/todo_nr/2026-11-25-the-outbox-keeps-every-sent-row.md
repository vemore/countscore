# The outbox keeps every row it has sent, for ever

- **Noted:** 2026-11-25 — fix/restored-device-own-deltas, choosing which outbox rows `_holdsOwn` reads
- **Theme:** sync-robustness
- **Area:** app
- **Blocks release:** no

`SyncStore.markSent` and `markSuperseded` set `sent_at` and nothing ever deletes the row
(`lib/services/sync/sync_store.dart`: the only `DELETE FROM outbox` are the coalescing in
`preparePush`, a pulled delete dropping *unsent* rows, and `leave`). Every shared edit leaves
a row with its JSON payload behind, so the outbox of a device in a group grows with its whole
sync history. The reads that matter filter on `sent_at IS NULL` through
`idx_outbox_group_unsent`, so it costs storage and backup size rather than speed today.

Nothing reads a sent row: `markSent` records the version in `entity_versions`, which is what
the pull compares against, and `_holdsOwn` reads unsent rows only — so a prune is safe as far
as the sync is concerned.

**Fix:** delete the row in `markSent` / `markSuperseded` instead of stamping `sent_at`, or
prune sent rows older than a few days at the start of a pass; the column can stay for
the rows a schema step or a test still reads.

**Acceptance:**
- After a pass that sends N deltas, the outbox holds no sent row (or none older than the
  retention).
- `sync_store_test.dart` and the real-server sync tests stay green.
