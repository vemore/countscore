# A pulled membership upsert brings back a player the group removed

**Status:** done (2026-11-25) — closed by fix/pulled-membership-keeps-delete. `_applyGamePlayer` matches a membership by its uuid and leaves a tombstone tombstoned; adding a player back — which had never worked on a shared game, the v9 unique index refused the insert — is now a new row under a new uuid (schema v24, a live-only index). The server still applies such an upsert: `wip/todo_nr/2026-11-25-the-server-applies-a-membership-upsert-over-its-delete.md`.

- **Noted:** 2026-11-25 — fix/restored-device-own-deltas, the review of #293 and its `merged_lww` real-server test
- **Theme:** sync-robustness
- **Area:** app
- **Blocks release:** no

The server says a delete wins: an upsert on a tombstoned row is answered `merged_lww` and
changes nothing there. But it **logs** that upsert (`backend/app/routes/sync.py`, `push`:
`applied` and `merged_lww` both write `change_log`), and every other device pulls it.
`SyncStore._applyOne` compares it with `entity_versions` only; when its
`(client_lamport, origin_device_id)` beats the delete's — the editing device's clock was
ahead — `_applyGamePlayer` updates the matched row with `'deleted_at': null`
(`lib/services/sync/sync_store.dart`, the `gp != null` branch). The removed player is back on
that device, and on no other, nor on the server.

Seen in `test/sync/sync_multi_group_backend_test.dart`, *merged_lww*: Y removes Alice, X's
colour change of her (higher lamport) is answered `merged_lww`; Y, pulling X's edit, shows
Alice again. The path predates #293. The other `_apply…` branches skip a tombstoned row
(`_isTombstoned`); this one looks the row up without `deleted_at IS NULL` and clears it.

**Fix:** on an upsert, leave a tombstoned `game_players` row tombstoned (as `_applyGame`,
`_applyRound` and `_applyScore` do), and match the live row only. Check first how a player
removed from a game and added back is stored locally (a new row, or the old one revived),
so the fix does not block that.

**Acceptance:**
- In the *merged_lww* real-server test, Y also shows Bob only after it pulls.
- A store test: a pulled upsert of a tombstoned membership, with a higher lamport than the
  delete, leaves it deleted.
