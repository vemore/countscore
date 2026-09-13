# Schema v10

> Scope: the mobile database — tables, the global-player model, the migration chain.
> Related: [[DataLayer]] · [[Sync]] · [[MobileApp]] · [[Testing]]
> Updated: 2026-09-13

This page was `SchemaV9` until v10 landed on 2026-09-13; links were renamed with it.
v11 followed the same day and is described here too.

## Facts

Schema version **11**, declared in two places that must stay in sync:
`lib/services/drift/database.dart` (`schemaVersion => 11`) and
`DatabaseService.schemaVersion` in `lib/services/database_service.dart`, which both
`openDatabase` calls use.

### Tables (12)

| Table | Role |
|---|---|
| `game_types` | Game types. uuid + sync columns. |
| `games` | Games. uuid, `group_id`, sync columns. |
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

### Upgrades on web (since v11)

Drift's `onUpgrade` is **not** a no-op any more. Native still never reaches it — sqflite has
migrated the file first — but a browser keeps its database across PWA releases, and the PWA
has been in production at v9 since 2026-09-13. `onUpgrade` runs `applySyncV10` for
`from < 10` and the v11 statements for `from < 11`: the same SQL sqflite runs, from
`sync_schema.dart`. Covered by `test/drift/web_upgrade_test.dart`.

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
