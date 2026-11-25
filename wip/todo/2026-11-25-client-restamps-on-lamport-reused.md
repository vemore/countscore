# The app does not re-stamp a delta the server refuses as `lamport_reused`

- **Noted:** 2026-11-25 — test/sync-adversarial-api (the server half)
- **Theme:** sync-robustness
- **Area:** app
- **Blocks release:** no

Since test/sync-adversarial-api, `POST /sync/push` answers `rejected` / `lamport_reused` when
this device already logged **another** delta under the same `client_lamport` — its clock went
back, typically a database restored from a backup (`.llmwiki/Sync.md`, push step 2, and
*Decisions & History*). Before, the server answered `duplicate` and dropped the payload.

`SyncEngine._resolve` (`lib/services/sync/sync_engine.dart`) has no case for it: the default
branch `markRejected`s the outbox row. The edit stays on the device and is counted as rejected
in Settings, but reaches the group only with the row's next local edit. No worse than before
(then it was marked sent and lost), not yet right.

**Fix:** a `case 'lamport_reused'` in `_resolve`: clear the outbox row's stamp
(`client_lamport = 0`, so `preparePush` re-stamps it and rebuilds the payload from the row as it
is now), `_pullAll()` — `applyPulled` raises `sync_state.last_lamport` past every lamport the
page carries, this device's own included —, return true so the pass pushes again. A second
`lamport_reused` on the same row (its `reject_reason` already says so, as `parent_missing`
does) is rejected as today: the pull did not reach the reused lamport, and looping would not
either. `lib/services/sync/` is being rewritten by feat/multi-group-storage: land after it.

**Acceptance:**
- A `sync_engine` test against a `MockClient` that answers `lamport_reused` once, then
  `applied`: the row is pushed again with a lamport above every lamport of the pull, and is
  marked sent.
- A second consecutive `lamport_reused` on the row marks it rejected, with no third push.
- `.llmwiki/Sync.md`, the client's answer table, has a `lamport_reused` row.
