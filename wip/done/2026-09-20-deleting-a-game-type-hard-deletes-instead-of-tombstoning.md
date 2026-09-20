# Deleting a game type hard-deletes the row, so the deletion cannot be expressed as a sync delta

**Status:** done (2026-09-20) — closed by fix/game-type-tombstone.
`DriftGameTypeRepository.delete` now tombstones a type the group knows (`_isLinked`, on
`group_links`, since a game type never carries a `group_id`) and hard-deletes one it does not;
the capture trigger turns the stamp into a `delete` delta, `_build` sends it and
`_applyGameType` applies it on the other device, sparing a type a live game still plays.
`leave` drops a game-type tombstone no game points at. The two leftovers the entry names are
filed: `2026-09-20-tombstoned-games-keep-a-gametypeid-cleanup-that-may-be-moot.md` and
`2026-09-20-a-re-created-game-type-can-never-sync-under-the-same-name.md`.

- **Noted:** 2026-09-20 — while fixing the game-type editor (`fix/game-type-editor`); named in that task as known and to be filed rather than fixed
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

`DriftGameTypeRepository.delete` (`lib/repositories/drift/drift_repositories.dart`) ends with

```dart
'DELETE FROM game_types WHERE id = ?'
```

while every other table in the same file soft-deletes **when the row is shared** — a
`deleted_at` stamp the capture triggers turn into a delete delta, which is what [[Sync]]
pushes and what `getAll` already filters on (`WHERE deleted_at IS NULL`). `game_types` carries
the column like the rest; only this one path ignores it.

**Corrected (2026-09-20, refinement).** The entry first said "every other table soft-deletes",
flatly. It does not: `DriftGameRepository.delete` (`drift_repositories.dart:147`) branches on
`if (await _isShared(_db, 'games', id))` → `_tombstone`, and falls back to a hard
`DELETE FROM games` (`:191`) for a row in no group; rounds (`:332`) and game_players (`:540`)
have the same shape, with the helper at `:44-56`. The fault is therefore narrower and more
precise than stated: **`game_types` is the only delete path with no shared/unshared branch at
all** — it hard-deletes a row that is in a group, which is exactly the case the others handle.

Consequences, in order of cost:

- **The deletion does not sync.** Another device in the group keeps the type; nothing ever
  tells it the row is gone, and the next pull can hand the row back.
- **The sync bookkeeping is orphaned.** The row disappears without the tombstone the delta
  log and the `(entity_type, uuid)` side tables key on.
- **The live-unique index on `builtin_key` (schema v15) frees the key outright** rather than
  through the "deleted copy does not block a live one" path the migration tests exercise.

Not urgent in practice: a type can only be deleted once no live game references it
(`countGames`, since 2026-09-20), and the sole user of production is on one device. It is the
one table where a delete has no delta, which is exactly the shape that bites when a second
device appears.

**Fix:** tombstone like the others — `UPDATE game_types SET deleted_at = ?, updated_at = ?
WHERE id = ?` — and check what already reads `game_types` without a `deleted_at IS NULL`
filter (the sync schema's back-fills among them, `lib/services/sync/sync_schema.dart`), plus
what the v15 live-unique index does with a tombstoned row. Worth checking whether the
`gameTypeId = NULL` cleanup for tombstoned games is still needed once the type itself is a
tombstone.

**Acceptance:**
- Deleting a game type leaves the row with a `deleted_at`, and `getAll` / `getById` no longer return it.
- The deletion is captured as a delta and applied on a second device (`test/sync/sync_store_test.dart` shape).
- A built-in type deleted, then seeded again, still yields one live row under the v15 index.
