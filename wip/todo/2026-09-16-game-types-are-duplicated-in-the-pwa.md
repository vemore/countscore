# Every game type appears twice in the production PWA

- **Noted:** 2026-09-16 — while smoke-testing #77 on the deployed PWA
- **Theme:** game-types
- **Area:** web
- **Blocks release:** no — the Play build is a separate database; only the PWA was seen

Opening **Types de jeux** on https://…/app/ lists each seeded type twice: Autre, Autre,
Belote, Belote, Bridge, Bridge, Président, Président, Rami, Rami, Scrabble, Scrabble,
Skyjo, Skyjo, Tarot, Tarot. Both copies of a type open correctly and both carry their
shipped rules, so this is duplicated rows, not a rendering fault.

**Not introduced by #77.** That change only `ALTER TABLE`s and `UPDATE`s
(`applyV13` in `lib/services/sync/sync_schema.dart`); nothing in it inserts a game type,
and `test/migration_v12_to_v13_test.dart` asserts the back-fill touches only rows already
present. The duplicates were in this browser's OPFS database before the deploy.

Cause not established. `_insertDefaultGameTypes()` is called only from Drift's `onCreate`
(`lib/services/drift/database.dart`), which should run once per database, so the plausible
explanations are a database recreated while an older one persisted, or an early prod check
that seeded by hand. The sqflite back-fill at `database_service.dart:387-420` cannot be it:
it only covers Skyjo, Président and Belote, and it never runs on web.

Worth noting either way: **there is no local uniqueness guard on a game type's name.** The
server has one — `live_unique("uq_game_types_group_name", "group_id", "name")` in
`backend/app/models/game.py` — and the sync pull already merges an incoming type onto a
local row of the same name (`_applyGameType`, `sync_store.dart`). The client has nothing
equivalent, so nothing stops a duplicate appearing or persisting.

**Fix:** reproduce on a fresh profile first (clear OPFS, reload, count the rows) to tell a
seeding bug from stale data in one browser. If seeding is sound, this is cleanup: a one-off
de-duplication that keeps the lowest `id` per `(name, group_id)` among `isDefault = 1` rows
and repoints any `games.gameTypeId` at the survivor — with the same care as the v9 player
merge (`.llmwiki/SchemaV10.md`). A `UNIQUE` index on live default rows would stop it
recurring, but it must not fire on the user's own types, which may legitimately share a
name with a deleted one.

**Decided (2026-09-18, refinement):** reproduce on a fresh OPFS profile first. If it does
not reproduce, clear that browser rather than write a de-duplication migration — but add the
uniqueness guard anyway, so a duplicate cannot come back.

**Acceptance:**
- The pull request records a fresh OPFS profile on the production PWA listing each seeded type once.
- The affected browser, cleared, lists each type once.
- A unique index on live default game types (on `builtin_key`, or name and group, chosen in the pull request) stops a second copy, and a test shows a user's own type may still share a name with a deleted one.
