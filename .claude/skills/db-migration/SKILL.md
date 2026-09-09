---
name: db-migration
description: Change the CountScore database schema — add a table, add a column, add a new entity, or write a migration. Covers the mobile side (Drift tables + the sqflite migration chain + repositories) and the server side (SQLModel + Alembic + sync handlers). Use when adding a persisted field or entity, bumping the schema version, or writing a migration test. Triggers: "add a table", "add a column", "nouvelle entité", "migration", "schema version", "bump schemaVersion", "alembic revision", "new model".
---

# Changing the CountScore schema

The mobile schema is **v9** and lives in two engines at once. The server schema is separate
and moves with it. Read `.llmwiki/SchemaV9.md` and `.llmwiki/DataLayer.md` before starting.

## The trap

`schemaVersion` is declared **twice** and both must be bumped together:

- `lib/services/drift/database.dart:30` → `int get schemaVersion => 9;`
- `lib/services/database_service.dart:51` → `version: 9,`

sqflite owns the migration chain on native. Drift's `onUpgrade` is **intentionally a
no-op** — by the time Drift opens the file, sqflite has already migrated it. Do not "fix"
that by mirroring the migration into Drift; you would then have two copies to keep in sync.

On web there is no legacy file, so Drift's `onCreate` builds the current version directly.
**Every schema change must be made in both places or web and native diverge.**

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
   `_createExtraIndexes()`; add any new index there.
5. **Bump both `schemaVersion` declarations.**
6. **Repository** — add the interface to `lib/repositories/`, then the implementation in
   `lib/repositories/drift/drift_repositories.dart`. Existing implementations use
   `db.customSelect`/`customInsert` with raw SQL; match that style.
7. **Provider** — wire it in `lib/providers/`, constructor-injectable like `GameProvider`.
8. **Regenerate**: `dart run build_runner build`.
9. **Tests**:
   - fresh-schema and CRUD in `test/database_service_test.dart`
   - a migration test modelled on `test/migration_v8_to_v9_test.dart` — build the *old*
     schema by hand, migrate, assert the data survived
   - repository lifecycle in `test/drift/drift_repositories_test.dart`

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
   drop-plus-add, which loses data.
4. **Sync handler** — register the entity's `apply_delta` handler in `ENTITY_HANDLERS`
   (`backend/app/routes/sync.py`). Easy to forget, and the entity silently never syncs
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
grep -n "version: " lib/services/database_service.dart
```

## Rules

- **Never break existing users.** They are live on the Play Store. A migration that can
  lose data is not shippable — see the two-release strategy in `.llmwiki/DataLayer.md`.
- `group_id IS NULL` means a local, unsynced row. Every new table must tolerate NULL.
- Local key is `INTEGER AUTOINCREMENT`; the UUID is the logical key for sync.
- Update `.llmwiki/SchemaV9.md` (rename the page if the version changes) and its
  `Updated:` date in the same commit.
