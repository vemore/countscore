# A repository insert does not wake sync

- **Noted:** 2026-11-25 — feat/multi-group-sync-sessions, writing the local-write wake test
- **Theme:** sync-robustness
- **Area:** app
- **Blocks release:** no

`_insertRow` (`lib/repositories/drift/drift_repositories.dart`) calls `db.customInsert`
without `updates:`, so Drift reports no table update for it. Every `create` that goes through
it — a game, a round, a score, a player's membership — reaches the outbox (the capture
triggers fire) but never reaches `GroupProvider`'s local-write listener
(`TableUpdateQuery.onAllTables`, `_scheduleWake`). Such a write is pushed by the next
trigger instead: a later update the repository does report (a score changed, a round
comment), the group's WebSocket signal for someone else's change, resume, or the 60 s poll.
A new round typed on a shared game can therefore take up to a minute to reach the other
devices when nothing else happens. Older than the multi-group change: the single-group loop
listened the same way.

**Fix:** pass `updates: {<the table>}` from `_insertRow` (it knows the table name; map it to
the Drift table), or have the callers pass it. Check the other `customInsert` /
`customStatement` writes of the repositories the same way.

**Acceptance:**
- A round created on a shared game, with no other write, wakes that group's session within
  the debounce (a provider test, like the wake test in
  `test/providers/group_provider_multi_group_test.dart`, using `rounds.create`).
