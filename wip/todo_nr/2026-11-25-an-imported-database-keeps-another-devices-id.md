# A database imported from another device of the same group keeps that device's id

- **Noted:** 2026-11-25 — feat/multi-group-storage, writing `reconcileMemberships`
- **Theme:** multi-group-sync
- **Area:** app
- **Blocks release:** no

`reconcileMemberships` (`lib/services/sync/sync_reconcile.dart`) pairs each `sync_state` row
with a stored token by **group id**. An export taken on phone X and imported on phone Y, both
in group G, passes: Y holds a token for G. But the imported row carries X's `device_id`, and
Y's token is Y's device on the server. `SyncStore._applyOne` then takes every pulled delta
whose `origin_device_id` is X's as "this device's own", and skips those it holds — so X's
later edits of an entity Y has pushed since never reach Y (`.llmwiki/Sync.md`, *Decisions &
History*, "A restored database applies the own deltas it never stamped") — and
`markSent` records Y's pushes in `entity_versions` under X's id.

**Fix:** on start, when a membership's token is held, compare `sync_state.device_id` with the
device the token names, and on a mismatch take the token's id and reset the cursor to 0 (a
pull from the start is idempotent). No endpoint says which device a token is today
(`backend/app/routes/`: `GET /groups/me` answers the group and its owner): the backend gains
the caller's id there first. Needs the network, so not in the local reconciliation.

**Acceptance:**
- A database exported on X and imported on Y (same group) pulls X's later edits on Y.
