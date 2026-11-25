# A sync pass running across a group switch reports "unauthorized" until the next poll

- **Noted:** 2026-09-26 — second independent review of [vemore/countscore#236](https://github.com/vemore/countscore/pull/236) (item 3)
- **Theme:** groups-v2
- **Area:** app
- **Blocks release:** no

`GroupProvider._stop` (`lib/providers/group_provider.dart`) cancels the poll timer, the
debounce, the local-writes listener and the stream, but not a `syncNow` pass already running.
`syncNow` builds its `SyncEngine` with the client and token of the moment, and the engine
re-reads membership on every page (`lib/services/sync/sync_engine.dart`). When `completeJoin`
(or `leave` then join) swaps the group while a pass is in flight, that pass works on the new
group's state with the old client and the just-revoked old token, gets a 401, sets
`SyncStatus.unauthorized`, and `break`s out of the `do … while (_rerun && _active)` loop,
dropping the `_rerun` that `_restart` queued. The new group then shows "unauthorized" and does
not sync until the next poll (60 s) or local write. It recovers on its own; it looks broken
meanwhile. Older than #236, which makes switching groups more common.

**Fix:** a generation counter bumped by `_stop`/`_restart`; a pass whose generation changed
underneath it exits without writing `_status`, and runs again if `_rerun` is set.

**Acceptance:**
- A switch during an in-flight pass ends with the new group synced and its status not `unauthorized`, without waiting for the poll (provider test with a slow mock server).
- A pass that outlives its generation writes neither `_status` nor the pending counts (provider test).
