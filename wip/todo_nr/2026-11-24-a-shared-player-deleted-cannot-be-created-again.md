# A player deleted while in a shared game cannot be created again under the same name

- **Noted:** 2026-11-24 — while fixing the player missing from shared game 191
- **Theme:** sync
- **Area:** app
- **Blocks release:** no — not seen in production; reproduced only in a unit test

`DriftPlayerRepository.deleteByName` tombstones a player that has a membership in a shared
game (`deleted_at` set, row kept, `lib/repositories/drift/drift_repositories.dart`). The
`players.name` column is unique over every row, tombstones included, while `_resolveGlobal`
looks for an existing player among live rows only (`deleted_at IS NULL`). So adding
"Thibaut" to any game after deleting a shared "Thibaut" inserts a second row with that name
and fails with `SqliteException(2067): UNIQUE constraint failed: players.name`. Found while
writing `test/sync/sync_store_test.dart`; what the UI shows when this happens is untested.

**Fix:** in `_resolveGlobal`, revive a tombstoned player of that name (clear `deleted_at`)
rather than inserting a new row, so its group link and its stats come back with it. The
alternative is a partial unique index over live rows only, but that is a schema migration.

**Acceptance:**
- Deleting a player who played a shared game, then adding that name to a new game, succeeds.
- The revived player keeps its `group_links` row, and the new game's membership is pushed.
