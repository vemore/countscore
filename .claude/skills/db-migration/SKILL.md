---
name: db-migration
description: Change the CountScore database schema — add a table, add a column, add a new entity, or write a migration. Covers the mobile side (Drift tables + the sqflite migration chain + repositories) and the server side (SQLModel + Alembic + sync handlers). Use when adding a persisted field or entity, bumping the schema version, or writing a migration test. Triggers: "add a table", "add a column", "nouvelle entité", "migration", "schema version", "bump schemaVersion", "alembic revision", "new model".
---

# Changing the CountScore schema

The mobile schema is **v16** and lives in two engines at once. The server schema is separate
and moves with it. Read `.llmwiki/SchemaV10.md` and `.llmwiki/DataLayer.md` before starting —
the page keeps its v10 name and documents every version since.

## The trap

`schemaVersion` is declared **twice** and both must be bumped together:

- `lib/services/drift/database.dart` → `int get schemaVersion => 16;`
- `lib/services/database_service.dart` → `static const schemaVersion = 16;`

sqflite owns the migration chain on native, and Drift never reaches `onUpgrade` there: by
the time Drift opens the file, sqflite has already migrated it.

**Web does reach it.** A browser keeps its database between PWA releases, and the PWA has
been in production since 2026-09-13, so Drift's `onUpgrade` is the *only* thing that
migrates a returning web user. Skipping it ships a PWA that never gets your change. It is
not a mirrored chain, though — write the step **once**, in
`lib/services/sync/sync_schema.dart`, as a function taking `execute` and `columnsOf`, and
call it from both `DatabaseService._upgradeDB` and `AppDatabase.onUpgrade`. `applySyncV10`
and `applyV12` are the two examples; the `columnsOf` guard is what makes replaying safe.

On web there is no legacy file at all for a *fresh* install, so Drift's `onCreate` builds
the current version directly. **Every schema change must be made in all three places —
`onCreate`, the sqflite chain and `onUpgrade` — or web and native diverge.**

## Mobile procedure

1. **Drift table** — `lib/services/drift/tables.dart`. Use `.named()` for any column whose
   name does not match Dart casing; the legacy schema is mixed-case (`gameTypeId`,
   `orderIndex`, `created_at`). New tables should carry the sync columns: `uuid`,
   `created_at`, `updated_at`, `deleted_at`, `group_id`.
2. **sqflite migration** — `lib/services/database_service.dart`, add an
   `if (oldVersion < N)` branch to `_upgradeDB`. Prefer `ALTER TABLE` and renames over
   recreate-and-copy: v9 renamed `players` → `game_players` precisely so that no `scores`
   row had to be rewritten.
3. **Fresh-install path** — update `createDB` so a new native install lands on the same
   shape the migration chain produces.
4. **Web `onCreate`** — `lib/services/drift/database.dart`: `m.createAll()` plus
   `_createExtraIndexes()`; add any new index there. `createAll()` picks up a new column on
   an existing table for free.
5. **Web `onUpgrade`** — same file: `if (from < N) await applyN(customStatement, _columnsOf);`
   for the shared step written in step 2. A returning PWA user gets your change from here and
   nowhere else.
6. **Bump both `schemaVersion` declarations.**
7. **Repository** — add the interface to `lib/repositories/`, then the implementation in
   `lib/repositories/drift/drift_repositories.dart`. Existing implementations use
   `db.customSelect`/`customInsert` with raw SQL; match that style.
8. **Provider** — wire it in `lib/providers/`, constructor-injectable like `GameProvider`.
9. **Regenerate**: `dart run build_runner build`.
10. **Tests**:
   - fresh-schema and CRUD in `test/database_service_test.dart`
   - a migration test modelled on `test/migration_v8_to_v9_test.dart` — build the *old*
     schema by hand, migrate, assert the data survived
   - extend `test/migration_v5_to_v10_test.dart`: it upgrades the schema production
     users actually have, through the production callbacks, and reads it back via Drift
   - repository lifecycle in `test/drift/drift_repositories_test.dart`. Note that
     `DriftGameRepository.update` lists its columns **by hand** — a new field is silently
     dropped there and nowhere else, so assert a round trip through `update`
   - the web upgrade path in `test/drift/web_upgrade_test.dart`: strip what your version
     added, stamp `user_version` back, reopen through Drift and assert it returned

## Server procedure

Only needed if the entity syncs.

1. **SQLModel** — `backend/app/models/`.
2. **Schemas** — `backend/app/schemas/` for request/response DTOs.
3. **Migration**:
   ```bash
   cd backend
   export DATABASE_URL=postgresql://...
   alembic revision --autogenerate -m "add x"
   alembic upgrade head
   ```
   Autogenerate works because `alembic/env.py` imports `app.models`. **Read the generated
   revision before applying it** — autogenerate misses renames and reads them as
   drop-plus-add, which loses data. Then `alembic check` must print
   `No new upgrade operations detected.` — the CI backend job runs upgrade, `downgrade base`,
   upgrade, then `check` on a fresh Postgres, so a `downgrade()` that does not run, or a model
   whose type differs from the revision's DDL, fails there.
4. **Sync handler** — register the entity's model in `_ENTITY_MAP` and its name in
   `EntityType` (`backend/app/routes/sync.py`, `backend/app/schemas/sync.py`). Easy to forget, and the entity silently never syncs
   without it.
5. **Tests** — `backend/tests/test_sync.py` for push/pull, LWW and idempotence.

## Verify

```bash
dart run build_runner build
flutter analyze && flutter test
cd backend && ruff check . && pytest -m 'not integration' -q
```

Then confirm both engines agree:
```bash
grep -n "schemaVersion" lib/services/drift/database.dart
grep -n "schemaVersion = " lib/services/database_service.dart
```

## Rules

- **Never break existing users.** They are live on the Play Store. A migration that can
  lose data is not shippable — see the two-release strategy in `.llmwiki/DataLayer.md`.
- `group_id IS NULL` means a local, unsynced row. Every new table must tolerate NULL.
- Local key is `INTEGER AUTOINCREMENT`; the UUID is the logical key for sync.
- Update `.llmwiki/SchemaV10.md` (rename the page if the version changes) and its
  `Updated:` date in the same commit.
