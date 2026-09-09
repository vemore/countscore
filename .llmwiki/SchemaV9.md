# Schema v9

> Scope: the mobile database — tables, the global-player model, the migration chain.
> Related: [[DataLayer]] · [[Sync]] · [[MobileApp]] · [[Testing]]
> Updated: 2026-09-09

## Facts

Schema version **9**, declared in two places that must stay in sync:
`lib/services/drift/database.dart:30` (`schemaVersion => 9`) and
`lib/services/database_service.dart:51` (`version: 9`).

### Tables (9)

| Table | Role |
|---|---|
| `game_types` | Game types. uuid + sync columns. |
| `games` | Games. uuid, `group_id`, sync columns. |
| `players` | **Global identity**: `(id, name, colorValue, uuid, group_id, …)`. UNIQUE on `name COLLATE NOCASE` where `group_id IS NULL`. |
| `game_players` | **Per-game membership**: `(id, gameId, player_id FK→players, name, orderIndex, colorValue, uuid, …)`. UNIQUE `(gameId, player_id)`. |
| `rounds` | `(gameId FK, roundNumber, comment, …)`. |
| `scores` | `(playerId FK→game_players.id, roundId FK, value, …)`. |
| `outbox` | Local sync queue `(entity_type, client_lamport, sent_at)`. Written by nobody yet. |
| `sync_state` | Per-group sync cursor `(last_server_seq, last_lamport)`. Unused so far. |
| `game_analyses` | ZapZap analysis cache. `gameId` UNIQUE, `content`, `modelId`, sync columns. |

Local key is `INTEGER AUTOINCREMENT`; the UUID is the logical key for sync. Every table
carries `uuid`, `created_at`, `updated_at`, `deleted_at` and `group_id`. All existing rows
have `group_id = NULL`, meaning local-only mode — so the sync columns are dormant, not wrong.

### Migration history

| Version | Change |
|---|---|
| v1→v5 | Successive sqflite evolutions: game types, colours, elimination conditions. |
| v6 | Sync-ready: `uuid`, `created_at`, `updated_at`, `deleted_at`, `group_id` on every table; `outbox` and `sync_state` added. |
| v7 | `game_analyses` table (ZapZap cache). |
| v8 | `game_analyses` recreated to add the sync columns missing from the Bedrock prototype. |
| **v9** | **Global players.** |

### The v9 migration in detail

`_upgradeV8toV9` — `lib/services/database_service.dart:435`:

1. The per-game `players` table is **renamed** to `game_players`. Ids are preserved, so
   `scores.playerId` needs no rewriting at all.
2. A new global `players` table is created, one row per human, unique by `(group_id, name)`.
3. `game_players.player_id` links membership to that global identity.
4. Deduplication collapses names by `lower(trim(name))`. Two players with the same name in
   the *same* game stay distinct: a `" (n)"` suffix is appended to the **global** name
   only, so the in-game display name is untouched.

Tested by `test/migration_v8_to_v9_test.dart`.

### `_ensureV6Shape`

Added in `b340c98`. Some installs recorded version 8 while still carrying pre-v6 tables
(no `uuid`, no `created_at`). Drift's `LazyDatabase` could not open those at all. This
repairs the shape before the rest of the chain runs.

## Decisions & History

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
