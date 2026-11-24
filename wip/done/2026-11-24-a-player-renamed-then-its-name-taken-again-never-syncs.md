# A new player under a name a renamed player was shared with never reaches the group

**Status:** done (2026-11-24) — `_link` mints a per-row identity for the newcomer and
re-sends the holder, a deleted player still sends its last name, linking re-enqueues the
player's memberships and scores, and an unlinked player's membership stays queued
(vemore/countscore#286).

- **Noted:** 2026-11-24 — production: shared game 191 shows six players on the phone that
  ran it (Thibaut among them) and five on every other device; Thibaut had been renamed before
- **Theme:** sync
- **Area:** app
- **Blocks release:** yes — data shared with the group is silently lost

A player keeps the group link of the name it was shared under through any rename. A new
player taking that name found its derived uuid held, and `_link`
(`lib/services/sync/sync_store.dart`) returned without a link. `_build` then gave `null` for
the newcomer's `game_player` and `score` rows, and `preparePush` deleted them from the
outbox: the group never saw the player, its place in the game or its scores.

**Fix:** see the Status line and [[Sync]].

**Acceptance:**
- A player shared, renamed, then a new player under the old name in a new shared game: the
  other device sees the new player with its scores (`sync_two_devices_test.dart`, "a new
  player under a name a renamed one was shared with reaches the other device").
- The renamed player keeps the original identity, the newcomer gets another one
  (`sync_store_test.dart`, "renamed, the name taken again gets an identity of its own").
- A player renamed then deleted before any sync: the other device drops the old membership,
  keeps the old person under the new name, and sees the newcomer with its own identity
  (`sync_two_devices_test.dart`, "a player renamed then deleted keeps its old games apart
  from a new player of its name"; `sync_store_test.dart`, "renamed then deleted, …").
- Memberships and scores an older build dropped are sent again once the player is linked
  (`sync_store_test.dart`, "linking a player sends again the memberships and scores an older
  build dropped").
