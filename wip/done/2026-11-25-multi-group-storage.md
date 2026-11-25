# Sync storage holds one membership, and its queue cannot tell groups apart

**Status:** done (2026-11-25) — closed by feat/multi-group-storage. Schema v23 (`applyV23`, both engines): `group_id` on `outbox`, `sync_inbox` and `entity_versions`, back-filled from the one membership, and capture triggers that queue a player or game type once per linked group; `SyncStore` and `SyncEngine` work per group, `join` adds and `leave(groupId)` purges one group only; credentials keyed by group id with the old pair moved on first read; `reconcileMemberships` settles an import on start. The nickname is stored (`SyncCredentials.nickname`) but not yet read by `GroupProvider`: `wip/todo_nr/2026-11-25-the-stored-nickname-is-not-read-by-group-provider.md`.

- **Noted:** 2026-11-25 — step 2 of `2026-11-17-belong-to-several-groups.md` (decisions there)
- **Theme:** multi-group-storage
- **Area:** app
- **Blocks release:** no

`outbox` and `sync_inbox` carry no `group_id`, `SyncStore.join` deletes every `sync_state`
row, `SyncStore.leave` empties all the sync tables, and `SyncCredentials` stores one pair of
tokens (`lib/services/sync/`). Nothing visible changes in this step.

**Fix** (skill `db-migration`, schema v23):
- `group_id` on `outbox`, `sync_inbox` and `entity_versions`, back-filled from the one
  membership an upgraded install has.
- Capture triggers: games and children enqueue `NEW.group_id`; players and game types enqueue
  **one row per group** they are linked in (`INSERT … SELECT FROM group_links`).
- `preparePush`, counts and the inbox replay filter on the group.
- `join` adds a `sync_state` row; `leave(groupId)` purges that group's rows only, and keeps a
  tombstoned player or game type that another group still links.
- Credentials keyed by group id; the two old keys migrated on first read, then deleted.
- The nickname (one for all groups) persisted on the device.

**Acceptance:**
- Migration test v22 → v23 with one group and a pending outbox: membership, credentials and
  every pending row kept, attributed to that group.
- A player linked in A and B, renamed once, yields one outbox row per group.
- `leave(A)` leaves B's `sync_state`, links, outbox, inbox and versions untouched.
- A database import (Settings → Import) whose `sync_state` names groups the credentials do not
  hold, or omits ones they do, ends in a defined state (test), not a sync that 401s for ever.
