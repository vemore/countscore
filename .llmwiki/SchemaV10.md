# Schema v10

> Scope: the mobile database — tables, the global-player model, the migration chain.
> Related: [[DataLayer]] · [[Sync]] · [[MobileApp]] · [[Testing]]
> Updated: 2026-09-19

This page was `SchemaV9` until v10 landed on 2026-09-13; links were renamed with it.
v11 followed the same day, v12, v13 and v14 on 2026-09-16, v15 on 2026-09-18 and v16 on
2026-09-19; all are described here too.

## Facts

Schema version **16**, declared in two places that must stay in sync:
`lib/services/drift/database.dart` (`schemaVersion => 16`) and
`DatabaseService.schemaVersion` in `lib/services/database_service.dart`, which both
`openDatabase` calls use.

### Tables (12)

| Table | Role |
|---|---|
| `game_types` | Game types. uuid + sync columns, `rules` and `rules_slug` since v13, `builtin_key` since v14, one live row per `builtin_key` since v15. |
| `games` | Games. uuid, `group_id`, sync columns, `finishedAt` since v12. |
| `players` | **Global identity**: `(id, name, colorValue, uuid, group_id, …)`. UNIQUE on `name COLLATE NOCASE` where `group_id IS NULL`. |
| `game_players` | **Per-game membership**: `(id, gameId, player_id FK→players, name, orderIndex, colorValue, uuid, …)`. UNIQUE `(gameId, player_id)`. |
| `rounds` | `(gameId FK, roundNumber, comment, …)`. |
| `scores` | `(playerId FK→game_players.id, roundId FK, value, …)`. |
| `outbox` | Local sync queue `(entity_type, client_lamport, sent_at)`, plus `rejected_at`, `reject_reason` since v10. Written by nobody yet. |
| `sync_state` | Per-group sync cursor `(last_server_seq, last_lamport)`, plus `device_id`, `group_name` since v10. Unused so far. |
| `game_analyses` | ZapZap analysis cache. `gameId` UNIQUE, `content`, `modelId`, sync columns. |
| `group_links` | v10. `(group_id, entity_type, local_uuid) → remote_uuid`, UNIQUE on the remote side: how a local player or game type is known in a group, since those merge by name. |
| `entity_versions` | v10. `(entity_type, entity_uuid) → (lamport, origin_device_id)`: the last writer of each synced entity, for client-side LWW. |
| `sync_inbox` | v10. Pulled deltas waiting for a parent that has not arrived, with the reason. |

Local key is `INTEGER AUTOINCREMENT`; the UUID is the logical key for sync. Every entity
table carries `uuid`, `created_at`, `updated_at`, `deleted_at` and `group_id`. All existing
rows have `group_id = NULL`, meaning local-only mode — so the sync columns are dormant, not
wrong.

The device token is **not** in the database: it belongs in platform secure storage.

### `game_types.rules` / `game_types.rules_slug` (since v13)

Both TEXT, nullable. `rules` is free Markdown the user wrote; NULL means the app shows the
ruleset it ships for `rules_slug` instead, in the current locale. `rules_slug` names one of
the 21 rulesets in `assets/rules/` — every built-in type but `Autre`, which has none — and exists as its own column
because `name` is user-editable — a renamed type must not lose its rules.

Both push as `rules` and `rules_slug`, columns the server gained in
`0003_game_type_rules`. Bounds in `backend/app/services/delta_bounds.py`: 8 000 and 32.
The client clips to the same lengths (`sync_store.dart`, `_gameTypeRulesMax`).
`defaultRulesSlugs` in `sync_schema.dart` maps each `builtin_key` to its slug; the seed
factories in `lib/models/game_type.dart` carry the same slugs
(`test/migration_v15_to_v16_test.dart` holds the two and `GameRulesCatalog.slugs` together).
The v13 back-fill ran before `builtin_key` existed and matched the nine pre-v14 seeded
names (`GameType.seededNamesBeforeV14`); the v16 back-fill matches the key, so the twelve
types of v14 get their rulesets whatever name the row stores. A renamed type loses its key
and keeps its slug, so it keeps its rules either way.

### `games.finishedAt` (since v12)

ISO-8601 TEXT, nullable; null means the game is still open. Set when the user declares a
game over — the board's overflow menu, the home-screen game menu, or the threshold
reached by the game type's rule, which opens the end screen — and cleared by reopening it
(or "Continue playing" on that screen). It locks nothing: a finished game
still takes rounds and score edits.

Pushed as `ended_at`, a column the server has carried since `0001_initial` and that nothing
ever wrote (`backend/app/models/game.py`). The payload always carries the key, null
included, so that reopening a game clears it on the other devices instead of leaving them
showing it as finished forever. `lib/services/sync/sync_store.dart`, `case 'game'` and
`_applyGame`.

### `game_types.builtin_key` (since v14)

TEXT, nullable. The stable identity of one of the 22 built-in types — `'zapzap'`,
`'other'`, `'yahtzee'`, … — and null for a type the user created or renamed.

**It carries the displayed name as well.** `lib/utils/game_type_name.dart` switches on it
to an `AppLocalizations` getter, and `name` is read only when it is null. That is the whole
point: the stored `name` of a built-in row becomes inconsequential, so two devices in two
locales hold different names for one type, and last-writer-wins on that column is harmless.
Renaming a built-in type in `lib/screens/game_types_screen.dart` **clears the key**, which
is what makes the chosen name stick.

`applyV14` in `lib/services/sync/sync_schema.dart`, run by both engines, does three things:

1. adds the column;
2. **back-fills every seeded row**, matched by the literal name it was seeded with *and* by
   `isDefault = 1` — the precedent is the v4→v5 step, `database_service.dart`. `isDefault` is
   what separates a row the app wrote from one the user made, so a user's own "Yahtzee" is
   never claimed and renamed under them. At most one row per key: the guard is on the key,
   not on the row, which is what makes a replay over a duplicated name safe;
3. **inserts the twelve types the pre-v14 seed never held**, when the key is absent *and* no
   live row already uses that name.

A type the user deleted is therefore **not** resurrected — the ten old ones are only ever
back-filled — and a user who had already made their own "Yahtzee" keeps one row rather than
gaining a second the server's `unique(group_id, name)` would refuse for good. Step 2 covers
all 22 rather than only the ten because the v2→v3 step seeds the *current* catalogue: a
device coming from v2 reaches v14 with all 22 names present and none of them keyed.
`test/migration_v13_to_v14_test.dart` and `test/migration_v2_to_v14_test.dart`.

> **A seed inside a migration step writes against an older table than the model describes.**
> sqflite builds its INSERT column list straight from the map keys, so one key too many is
> `SqliteException(1): table game_types has no column named …`, thrown inside `onUpgrade` —
> the open fails and the database is unopenable for good, not silently trimmed.
> `DatabaseService._gameTypeRow` filters `GameType.toMap()` against the table as it is at
> that point, and every seed in the chain goes through it.

Pushed as `builtin_key`, a column the server gained in `0004_game_type_builtin_key`. The
group link of a built-in type is derived from the key rather than the name
(`linkedGameTypeRemoteUuid`, `lib/services/sync/sync_ids.dart`), so two devices in different
locales compute the same server uuid. See [[Sync]].

### One live row per built-in type (since v15)

`idx_game_types_builtin_key_live` (the constant `gameTypesBuiltinKeyIndex`): UNIQUE on
`game_types(builtin_key) WHERE builtin_key IS NOT NULL AND deleted_at IS NULL`. A second
live copy of a built-in type is refused whatever name it carries; a deleted copy does not
block a live one; a type the user made has no key and is never constrained, so it may share
its name with a deleted type or with anything else.

`applyV15` in `lib/services/sync/sync_schema.dart` is the upgrade step of both engines *and*
part of both fresh installs (`DatabaseService._createDB`, Drift `onCreate`), run before the
seed. Before creating the index it clears the key of any surplus live row holding a key an
older live row already holds — the row, its games and its settings stay; it only shows its
stored name. Nothing in the app is known to produce such a row, but a `CREATE UNIQUE INDEX`
that fails inside `onUpgrade` would leave the database unopenable, so the step does not
assume it.

> **Status: Outdated** (2026-09-19) — "nothing in the app is known to produce such a row"
> was wrong on the web: a PWA reload reran Drift `onCreate` on a full database (the schema
> version never reached IndexedDB, [[Web]] § Persistence), and before this index every rerun
> seeded the built-in types again — the likely origin of the duplicates. Since v15 the rerun
> failed on this index instead. Drift `onCreate` now seeds with `INSERT … WHERE NOT EXISTS
> (builtin_key)` (`_insertDefaultGameTypes`, `lib/services/drift/database.dart`), so a rerun
> adds nothing and completes; a tombstoned built-in is not resurrected, a hard-deleted one is.

The sync pull honours it: `_applyGameType` (`lib/services/sync/sync_store.dart`) drops an
incoming `builtin_key` from the update of a linked row when another live local row already
holds that key — a row linked by name before its remote became a built-in. Tests:
`test/migration_v14_to_v15_test.dart`, `test/sync/sync_store_test.dart`,
`test/drift/web_upgrade_test.dart`.

### Upgrades on web (since v11)

Drift's `onUpgrade` is **not** a no-op any more. Native still never reaches it — sqflite has
migrated the file first — but a browser keeps its database across PWA releases, and the PWA
has been in production at v9 since 2026-09-13. `onUpgrade` runs `applySyncV10` for
`from < 10`, the v11 statements for `from < 11`, `applyV12` for `from < 12`, `applyV13`
for `from < 13`, `applyV14` for `from < 14` and `applyV15` for `from < 15`: the same SQL sqflite runs, from `sync_schema.dart`. Covered by
`test/drift/web_upgrade_test.dart`.

### Tombstones (since v10)

`deleted_at` is live. `lib/repositories/drift/drift_repositories.dart` deletes a row
outright when its `group_id` is NULL, exactly as before, and **tombstones** it otherwise —
a shared game with its rounds, scores, memberships and analysis; a shared round with its
scores; a shared membership with its scores. `deleteByName` tombstones the global player
only when a shared membership still points at it. Every read of games, game types, rounds,
scores and analyses filters `deleted_at IS NULL`, and the statistics join only live games
and scores. Deleting a game type ignores tombstoned games and clears their `gameTypeId`.

### Migration history

| Version | Change |
|---|---|
| v1→v5 | Successive sqflite evolutions: game types, colours, elimination conditions. |
| v6 | Sync-ready: `uuid`, `created_at`, `updated_at`, `deleted_at`, `group_id` on every table; `outbox` and `sync_state` added. |
| v7 | `game_analyses` table (ZapZap cache). |
| v8 | `game_analyses` recreated to add the sync columns missing from the Bedrock prototype. |
| v9 | Global players. |
| **v11** | **Change capture**: `sync_flags` (one row, `suppress`), `trg_sync_*` capture triggers on games, game_players, rounds, scores, game_analyses (insert/update when `group_id` is set) and on players, game_types (update when linked), and `*_inherit` triggers that give a row inserted under a shared parent its `group_id`. SQL in `lib/services/sync/sync_schema.dart`, shared by both engines. |
| **v13** | **`game_types.rules` / `game_types.rules_slug`** (both TEXT, nullable): the rules a group wrote for a type, and the shipped ruleset it falls back to. `applyV13` in `lib/services/sync/sync_schema.dart`, run by both engines. Additive, plus a back-fill that maps the ten seeded names to their slug — `UPDATE`s only, so a type the user deleted is not resurrected and a renamed one keeps a NULL slug. |
| **v12** | **`games.finishedAt`** (ISO-8601 TEXT, nullable): an explicit end for every game, not only the three types that carry a threshold. `applyV12` in `lib/services/sync/sync_schema.dart`, run by both engines. Additive only. |
| **v14** | **`game_types.builtin_key`** (TEXT, nullable): the stable identity *and* the source of the displayed name of a built-in type, plus the twelve types the seed was missing. `applyV14` in `lib/services/sync/sync_schema.dart`, run by both engines. Additive; back-fills, never resurrects. |
| **v15** | **Unique index on live built-in game types** (`builtin_key`, live rows only). `applyV15` in `lib/services/sync/sync_schema.dart`, run by both engines on upgrade and on a fresh install. Clears a surplus key rather than failing; deletes nothing. |
| **v16** | **Rulesets for the twelve types of v14**: `rules_slug` back-filled by `builtin_key`, where it is still NULL. `applyV16` in `lib/services/sync/sync_schema.dart`, run by both engines. No column change; `UPDATE`s only, so nothing deleted comes back, a slug already set is kept and a renamed type (no key) is left alone. `test/migration_v15_to_v16_test.dart`. |
| v10 | **Sync bookkeeping**: `group_links`, `entity_versions`, `sync_inbox`; `outbox.rejected_at` / `reject_reason`; `sync_state.device_id` / `group_name`. Additive only — `_createSyncV10Tables` is the fresh-install and the upgrade path at once. |

### The v9 migration in detail

`_upgradeV8toV9` in `lib/services/database_service.dart`:

1. The per-game `players` table is **renamed** to `game_players`. Ids are preserved, so
   `scores.playerId` needs no rewriting at all.
2. A new global `players` table is created, one row per human, unique by `(group_id, name)`.
3. `game_players.player_id` links membership to that global identity.
4. Deduplication collapses names by `lower(trim(name))`. Two players with the same name in
   the *same* game stay distinct: a `" (n)"` suffix is appended to the **global** name
   only, so the in-game display name is untouched.

Tested by `test/migration_v8_to_v9_test.dart`.

### The upgrade production users take

The Play Store build is 1.0.1, on sqflite **v5** (tag `1.0.1+3`). The next release runs
v5 → v10 and then hands the file to Drift. `test/migration_v5_to_v10_test.dart` builds a
real v5 file from that tag's DDL, upgrades it through `DatabaseService.openForTesting` — the
production `version` and callbacks — reopens it with Drift and reads every game, player,
score and statistic back.

### `_ensureV6Shape`

Added in `b340c98`. Some installs recorded version 8 while still carrying pre-v6 tables
(no `uuid`, no `created_at`). Drift's `LazyDatabase` could not open those at all. This
repairs the shape before the rest of the chain runs.

## Decisions & History

- **v10 adds tables, it does not add a column per synced row (2026-09-13).** The sync
  client needs, per entity, the last `(lamport, device)` and, for players and game types,
  a server uuid that can differ from the local one. Columns on six tables would have meant
  six `ALTER TABLE`s on every user's data and a Drift table change each; two side tables
  keyed by `(entity_type, uuid)` touch no existing row. See [[Sync]].
- **A built-in type's identity is a key, not its name (2026-09-16).** `name` was the key
  in five places at once — the cross-device match, the server's `unique(group_id, name)`,
  the ZapZap detection, the statistics grouping and the form's default type — which is
  exactly why the seeded names could not simply be translated. Making the name localized
  and the identity a separate column decouples them: `builtinKey` carries both the identity
  and the displayed name, and `name` survives only as the fallback for rows that have no
  key. The alternative — translating the rows in place at each locale change — would have
  fought the user's own renames and still left two devices in two locales disagreeing.
- **The twelve new types are appended, never inserted (2026-09-16).** The first ten indices
  of `defaultGameTypes()` are what an install seeded before v14 already holds, in order;
  `test/models_test.dart` pins them. Inserting one in the middle would silently change what
  the v14 back-fill matches.
- **v12 adds a column although v10 deliberately did not (2026-09-16).** The v10 decision
  below rejected "a column per synced row" — that was six `ALTER TABLE`s across six tables
  for bookkeeping keyed by `(entity_type, uuid)`, which two side tables express better.
  `finishedAt` is the opposite case: one nullable column on one table, holding a fact about
  the game itself that every read of a game wants. A side table would have meant a join on
  every game list for one timestamp.
- **The end of a game is a timestamp, not a flag (2026-09-16).** `finishedAt` answers "when"
  as well as "whether", which a boolean cannot, and it costs the same. It also maps onto the
  server's existing `ended_at` with no migration at all.
- **The local guard on game types is on `builtin_key`, not on `(group_id, name)` (2026-09-18).**
  Every seeded type appeared twice in one production browser (wip entry
  `2026-09-16-game-types-are-duplicated-in-the-pwa`); a fresh profile on the production PWA
  listed each of the 22 once, so it was stale data in that browser, not a seeding bug, and
  no de-duplication migration was written — clearing that browser is the fix. The guard
  stops it coming back. The key, because it is the identity of a built-in type since v14 and
  the name is not — two locales store two names for one type, which a name index would never
  catch — and because it mirrors the server's `uq_game_types_group_builtin_key`. Global
  rather than per group, because one local row stands for a built-in type in every group the
  device is in. A name index was rejected: it would constrain the user's own types, which
  may legitimately share a name.
- **`defaultRulesSlugs` is keyed on `builtin_key`, with a back-fill of its own (2026-09-19).**
  It was keyed on the seeded name, which v14 made the wrong identity: the name is
  user-editable and not even what is displayed. Re-keying it could not reach the twelve rows
  v14 had already inserted without a slug, hence v16 — a data-only step, bumped like any
  other so both engines run it exactly once. The v13 step still matches names, through
  `seededNamesBeforeV14`, because at that point of the chain there is no key to match.
- **Tombstone shared rows only (2026-09-13).** A delete has to reach the other devices, so
  a shared row cannot vanish; a local row has nobody to tell, and tombstoning it would grow
  every existing user's database forever for nothing.

- **A player is unique within a group, not within a game and not globally.** The per-game
  model perpetuated the `getPlayerStats` bug, which aggregated every "Alice" across every
  game into one set of statistics; keying stats by a global UUID fixes it. A truly
  cross-group identity was rejected: no real use case, and it would break "Alice from the
  family" ≠ "Alice from the club".
- **Rename rather than recreate.** Renaming `players` → `game_players` preserves the
  integer ids, so not a single `scores` row has to be rewritten. A recreate-and-remap
  migration would have touched every score in the database — far more risk for no gain.
- **Deduplication is case- and whitespace-insensitive, but disambiguation only touches the
  global name.** Users type "alice" and "Alice " and mean one person; but two genuinely
  different Alices in one game must both keep showing as "Alice" on the board.
- **`group_id IS NULL` means local.** This is what makes v9 safe for every existing user:
  their data migrates into the new shape and keeps working with no groups, no server and
  no account.
