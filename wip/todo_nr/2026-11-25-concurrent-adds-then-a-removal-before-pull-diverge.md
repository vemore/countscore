# Two devices add the same player, one removes it before pulling the other's add, and they disagree

- **Noted:** 2026-11-25 — fix/pulled-membership-keeps-delete, the review of #295
- **Theme:** sync-robustness
- **Area:** app
- **Blocks release:** no — it needs the same player added to one shared game on two devices concurrently, then removed on one of them before it syncs

A membership is identified by its uuid, and each device that adds a player mints its own
(`DriftPlayerRepository.create`). `SyncStore._applyGamePlayer` merges a pulled uuid it has never
seen into the live `(game, player)` row and records the alias (`game_player_aliases`, schema v24).
When there is no live row, it inserts the pulled uuid as a new membership, because that is what a
player added back on another device looks like.

The scenario:
1. X adds Alice to a shared game as U0; Y, offline, adds her as U1.
2. X syncs (U0 logged). Y, still offline, removes Alice: U1 is a tombstone on Y.
3. Y syncs. The outbox coalesces U1's add and removal into one delete of U1, which the server
   applies to the pair, X's row included. Y pulls U0, finds no live row for the pair and
   inserts U0: Alice is back on Y.
4. X pulls the delete of U1, a uuid it has never seen, and falls back to the live row of the
   pair, U0: Alice is removed on X.

Result: Y shows Alice, X does not, and nothing reconciles them. The server holds neither: it
keys `(game, player)`, and the delete came last
(`wip/todo_nr/2026-11-25-the-server-applies-a-membership-upsert-over-its-delete.md`).

On Y, step 3 cannot tell U0 (an add concurrent with its removal, which the removal should beat)
from a re-add made after the removal (which should win). Both are a never-seen uuid arriving
while the pair has only a tombstone.

**Fix (proposed):** decide by the `(client_lamport, origin_device_id)` order, which every device
compares the same way. When
a never-seen membership upsert arrives while the pair holds only a tombstone, compare the upsert's
`(client_lamport, origin_device_id)` with the version of the delete that made the tombstone
(`entity_versions` of the tombstoned uuid). Insert only when the upsert is newer, the way a
re-add would be. When it is older, treat it as merged into the tombstone instead and record the
alias, so that Y ends as X does.

Lamports only approximate causality, so first check whether a re-add can carry a lower lamport
than the removal it follows. It cannot when the re-adding device pulled or made that removal:
its next stamp is past every lamport it has seen. The alternative is a deterministic uuid for the
first membership of a pair, uuid5(game, player), as players get through `group_links`, so that
concurrent adds share one uuid and there is nothing to merge. That also needs the server's
membership identity (see the entry above).

**Acceptance:**
- A store test of the scenario above: after both devices apply the same deltas, both show the
  same membership list for the game.
- A player removed and then added back on another device (`sync_store_test.dart`, "added back
  on another device") still comes back.
- The real-server test in `sync_multi_group_backend_test.dart` passes with the scenario added.
