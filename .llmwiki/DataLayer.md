# Data Layer

> Scope: how the app reaches SQLite — Drift, the sqflite bootstrap, repositories, codegen.
> Related: [[SchemaV9]] · [[MobileApp]] · [[Web]] · [[Testing]] · [[Sync]]
> Updated: 2026-09-09

## Facts

**Drift owns all runtime CRUD.** sqflite is still a dependency, but no provider and no
screen calls it for reads or writes.

### Where sqflite still lives

All three remaining roles are inside `lib/services/database_service.dart` (1468 l.):

1. `bootstrapMigrate()` — called only from `connection_native.dart`. Opens the legacy
   `countscore.db`, runs the v1→v9 sqflite migration chain, closes it. Drift then adopts
   the same file.
2. **Export / import** of the database — needs `dart:io`, so mobile only. Called from
   `settings_provider.dart`.
3. **Test fixtures** — `createDB` and `upgradeV8toV9` are exposed `@visibleForTesting`.

### Drift

- `lib/services/drift/tables.dart` (162 l.) — 9 table declarations mirroring the v9 sqflite
  schema, using `.named()` to keep the legacy mixed-case column names (`gameTypeId`,
  `orderIndex`, `created_at`).
- `lib/services/drift/database.dart` — `AppDatabase`, `schemaVersion => 9` at line 30.
  `onUpgrade` is **intentionally a no-op**: by the time Drift opens the file, sqflite has
  already brought it to 9, so Drift sees 9 == 9. `onCreate` (web, fresh install) builds v9
  directly: `m.createAll()` + `_createExtraIndexes()` (20 indexes) + `_insertDefaultGameTypes()`.
- `lib/services/drift/connection/connection.dart` is a three-line conditional export:
  `export 'connection_web.dart' if (dart.library.io) 'connection_native.dart';`

### Repositories

`lib/repositories/` holds **seven abstract interfaces only** — game, player, round, score,
game_type, player_stats, game_analysis. The single set of implementations is
`lib/repositories/drift/drift_repositories.dart` (712 l.).

Those implementations use `db.customSelect` / `customInsert` with **raw SQL**, a faithful
port of the old sqflite queries, rather than Drift's typed query DSL. That was a
deliberate migration shortcut, not an oversight — but it means the type-safety argument for
Drift is only partly cashed in so far.

### Code generation

`database.g.dart` is 7754 lines, generated, and **gitignored** (`.gitignore:117 *.g.dart`).
A clean checkout does not compile until:

```bash
dart run build_runner build --delete-conflicting-outputs
```

`build_runner` codegen works fine. The `drift_dev` **CLI** does not build at all at the
pinned versions — see `TODO.md` and [[KnownLimits]].

## Decisions & History

- **Drift over sqflite, Floor, Isar and ObjectBox.** sqflite has no web support, which
  alone disqualified it once the PWA became an axis. Drift is cross-platform via
  `sqlite3.wasm`, generates type-safe code (the class of bug that produced the
  `getPlayerStats` defect), has a clean testable `MigrationStrategy` and native
  transactions. Floor is less maintained with weaker web support; Isar is fast but not SQL,
  making the existing queries an invasive rewrite; ObjectBox turns commercial past a
  certain usage.
- **Two-release rollout, not a big-bang switch.** Users are live on the Play Store and
  data loss is unacceptable. Release N ships the sqflite v8→v9 migration with the app still
  running on sqflite — if it breaks, roll back and the app still works. Release N+1 turns
  Drift on, and `bootstrapMigrate()` hands it an already-migrated file. Production is
  currently at Release N.
- **`onUpgrade` is a no-op rather than a mirrored migration chain.** Maintaining the same
  migration twice, once per engine, would guarantee the two drift apart. sqflite is the
  single source of migration truth on native; on web there is no legacy file, so `onCreate`
  is the only path that runs.
