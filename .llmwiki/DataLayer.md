# Data Layer

> Scope: how the app reaches SQLite — Drift, the sqflite bootstrap, repositories, codegen.
> Related: [[SchemaV10]] · [[MobileApp]] · [[Web]] · [[Testing]] · [[Sync]]
> Updated: 2026-09-20

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
  `orderIndex`, `created_at`, `builtin_key`).
- `lib/services/drift/database.dart` — `AppDatabase`, `schemaVersion => 11`.
  `onUpgrade` is **intentionally a no-op**: by the time Drift opens the file, sqflite has
  already brought it to 9, so Drift sees 9 == 9. `onCreate` (web, fresh install) builds v9
  directly: `m.createAll()` + `_createExtraIndexes()` (20 indexes) + `_insertDefaultGameTypes()`.

  > **Status: Outdated** (2026-09-16, current number 2026-09-20) — both bullets above:
  > `tables.dart` declares **12** tables since v10, and `onUpgrade` has replayed the
  > post-v9 steps since v11. `_insertDefaultGameTypes()` now seeds 22 types, each with its
  > `builtin_key`. The version number is deliberately not repeated here any more — it moves
  > with every schema change and [[SchemaV10]] owns it.
- On the web the executor is wrapped in `PersistenceFlushInterceptor`
  (`lib/services/drift/connection/persistence_flush.dart`): drift's IndexedDB storage would
  otherwise leave committed transactions and the schema version unwritten until the next
  non-transactional statement. See [[Web]] § Persistence.
- `lib/services/drift/connection/connection.dart` is a three-line conditional export:
  `export 'connection_web.dart' if (dart.library.io) 'connection_native.dart';`

### Repositories

`lib/repositories/` holds **seven abstract interfaces only** — game, player, round, score,
game_type, player_stats, game_analysis. The single set of implementations is
`lib/repositories/drift/drift_repositories.dart` (921 l.).

`DriftGameTypeRepository.update` builds its assignment list from `GameType.toMap()`, so a
new column reaches it for free — unlike `DriftGameRepository.update`, which lists its
columns by hand. `test/drift/drift_repositories_test.dart` pins the `builtinKey` round trip
either way.

The statistics aggregates group on `COALESCE(gt.builtin_key, gt.name, 'Unknown')` rather
than on `gt.name`: the name of a built-in type is localized, so grouping on it would split
one player's Yahtzee statistics the day they switched the phone's language.

Those implementations use `db.customSelect` / `customInsert` with **raw SQL**, a faithful
port of the old sqflite queries, rather than Drift's typed query DSL. That was a
deliberate migration shortcut, not an oversight — but it means the type-safety argument for
Drift is only partly cashed in so far.

### Code generation

`database.g.dart` is 7754 lines, generated, and **gitignored** (`.gitignore:117 *.g.dart`).
A clean checkout does not compile until:

```bash
dart run build_runner build
```

`build_runner` 2.16 **removed `--delete-conflicting-outputs`**: passing it now prints
*"These options have been removed and were ignored"*. Just run the command above.

The `drift_dev` CLI works at drift 2.34.4 / drift_dev 2.34.6 — `dart run drift_dev analyze`
returns *No errors found*. It did not compile at all at drift_dev 2.34.0. Note that
`make-web-worker` is **not** one of its subcommands (`analyze`, `identify-databases`,
`make-migrations`, `schema`); the web worker comes prebuilt with the drift package instead.
See [[Web]].

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

  > **Status: Outdated** (2026-09-13) — Release N never shipped. The Play Store still has
  > 1.0.1 (tag `1.0.1+3`, sqflite schema **v5**, no Drift), so the next release runs v5 →
  > v10 *and* switches to Drift in one go — and, by the user's decision of 2026-09-13, also
  > carries group sync. The two-release safety net is gone; what replaces it is
  > `test/migration_v5_to_v10_test.dart`, which upgrades a real v5 file and reads it back
  > through Drift. See [[SchemaV10]].
- **`onUpgrade` is a no-op rather than a mirrored migration chain.**

  > **Status: Outdated** (2026-09-13) — true for native, wrong for web: a browser that ran
  > the v9 PWA upgrades through Drift alone. `onUpgrade` now replays the post-v9 steps from
  > the SQL shared with sqflite (`lib/services/sync/sync_schema.dart`). Not a mirrored chain:
  > only steps after v9, one source for both engines. See [[SchemaV10]].
 Maintaining the same
  migration twice, once per engine, would guarantee the two drift apart. sqflite is the
  single source of migration truth on native; on web there is no legacy file, so `onCreate`
  is the only path that runs.
