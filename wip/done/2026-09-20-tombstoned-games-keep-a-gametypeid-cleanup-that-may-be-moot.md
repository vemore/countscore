# Deleting a game type still clears `gameTypeId` on tombstoned games, which may now be moot

**Status:** done (2026-09-24) — closed by fix/game-type-tombstone-keeps-gametypeid. `DriftGameTypeRepository.delete` clears `gameTypeId` on tombstoned games only on the hard-delete branch; the tombstone branch leaves them alone, so no game is re-enqueued and the history stays.

- **Noted:** 2026-09-20 — while tombstoning game-type deletes (`fix/game-type-tombstone`);
  named in that task as a leftover to file rather than decide
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

`DriftGameTypeRepository.delete` (`lib/repositories/drift/drift_repositories.dart`) opens with

```dart
UPDATE games SET gameTypeId = NULL WHERE gameTypeId = ? AND deleted_at IS NOT NULL
```

It dates from the hard delete: a tombstoned game held a foreign key into a row that was about
to disappear, so the key had to go first. Now that a shared type is tombstoned instead of
removed, the row it points at stays, and the statement has two costs:

- **It writes to shared games for nothing.** The UPDATE fires the capture trigger on every
  tombstoned game of the group, so each one is enqueued again — a second `delete` delta for a
  game the group already deleted. Harmless (the server dedups on the entity and a delete is
  idempotent), but it is outbox traffic with no content.
- **It destroys history.** A game deleted on one device and restored from a pull — or read by
  a future undelete — has lost which type it was played with, while the type itself is still
  there under its tombstone.

For a type the group never saw, the hard delete is still what runs, and the FK is declared
`ON DELETE SET NULL` (`database_service.dart:118`) anyway, so SQLite would do the same thing.

**Fix:** decide, then do one of two things — run the cleanup only on the hard-delete branch
(the tombstone branch leaves `gameTypeId` alone), or drop it outright and lean on
`ON DELETE SET NULL`. Check the Drift schema declares that FK action too, not only the
sqflite one.

**Decided (2026-09-24, refinement):** run the cleanup on the hard-delete branch only; the
tombstone branch leaves `gameTypeId` alone. Not dropped outright: the Drift schema declares no
foreign key on `gameTypeId` (`lib/services/drift/tables.dart:44`), only the sqflite chain does.

**Acceptance:**
- Deleting a game type the group knows leaves every tombstoned game's `gameTypeId` untouched.
- No extra outbox row is enqueued for a game that was already deleted.
- Deleting a type no group knows still leaves no game pointing at a row that is gone.
