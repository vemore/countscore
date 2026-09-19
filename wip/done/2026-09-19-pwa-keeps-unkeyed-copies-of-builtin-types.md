# A PWA that lived through the reload bug lists every original game type twice

**Status:** done (2026-09-19) — closed by fix/v17-dedupe-builtin-types. `applyV17` (`lib/services/sync/sync_schema.dart`), schema v17, run by the sqflite chain and by Drift's `onUpgrade`, soft-deletes a live, keyless, group-less type with no `rules` of its own when a live built-in row has the same stored name and scoring fields and no game, live or deleted, points at it. Tests: `test/migration_v16_to_v17_test.dart` (native and web paths).

- **Noted:** 2026-09-19 — smoke-testing #153 (`fix/pwa-reload-persistence`) on the production PWA, in a browser profile used since 2026-09-13
- **Theme:** web
- **Area:** web
- **Blocks release:** no — Android never had the reload bug; on the web only browsers used before v15 are affected, and nothing is lost

Before #153 every PWA reload reran `onCreate` (`wip/done/2026-09-19-pwa-reload-reruns-the-database-creation.md`).
Before v15 (#103) that rerun silently inserted the ten original built-in types again. v15
(`applyV15`, `lib/services/sync/sync_schema.dart`) then strips `builtin_key` from each surplus
live copy rather than deleting it — "never its data". So those copies survive as user types
under their stored French names.

In the smoke-test profile, after #153 recovered it (`user_version` 16, no errors), "Game
Types" lists Autre + Other, Belote ×2, Bridge ×2, Président ×2, Rami ×2, Scrabble ×2, Skyjo ×2,
Tarot ×2, Uno ×2 and ZapZap ×2. The database read back from IndexedDB holds rows 11–20: the ten
originals with `builtin_key` NULL, no `group_id`, and **no game** (every game points at row 1).

**Fix:** a migration step (v17, shared by both engines like `applyV15`) that soft-deletes a
live, keyless, group-less game type when a live built-in row has the same stored name *and*
the same scoring fields, and no game, live or deleted, references it. Soft delete, so sync
sees a tombstone. Leave any copy that has a game: it is the user's now.

**Acceptance:**
- A migration test: a v16 database holding a keyless copy of `zapzap` with no game ends with
  that copy deleted; a keyless copy with one game and a user type named "Tarot" with
  different scoring are both kept.
- The same test passes on the sqflite (native) and Drift (web) paths.
