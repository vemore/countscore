# A pre-v24 device revives a removed membership, and the group then disagrees about that player

- **Noted:** 2026-11-25 — the review of #295 (fix/pulled-membership-keeps-delete)
- **Theme:** sync-robustness
- **Area:** app
- **Blocks release:** no — it needs a device of the group still on the previous release, a player removed and added back, then an edit of that player on the old device

From schema v24 a player removed from a shared game and added back is a **new** membership
(new uuid), and a pulled upsert of a tombstoned membership changes nothing
(`SyncStore._applyGamePlayer`). A device still on v23 handles the added-back membership the
old way: it finds the tombstoned `(game, player)` row, clears `deleted_at` and keeps the
**old** uuid. Its later colour or order change, or its removal of that player, is then pushed
under the old uuid. v24 devices hold that uuid as a tombstone, so they ignore it: the old
device has removed the player, while the others still show them, or the reverse. The server
answers `applied` either way (it keys memberships by `(game, player)`).

There is no sound mitigation on the v24 side. The one the review proposed — act on a pulled
edit or delete of a tombstoned uuid when the pair also has a live row — cannot be told apart
from the stale edit this release fixed (`wip/done/2026-11-25-a-pulled-membership-upsert-undoes-a-delete.md`):
both are an upsert of a tombstoned uuid, under a higher lamport than its delete.

**Fix:** none in the client. Either accept it until the group has upgraded (documented in
`.llmwiki/Sync.md`), or have the server refuse a `game_player` delta from a client older than
v24 once a minimum client version is reported. Revisit if a report shows up.

**Acceptance:**
- A decision is recorded: accepted as is (entry dropped), or a minimum client version for
  `game_player` deltas exists and is tested in `backend/tests/test_sync.py`.
