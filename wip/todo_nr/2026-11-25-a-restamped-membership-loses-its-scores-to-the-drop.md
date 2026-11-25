# A membership re-stamped after `lamport_reused` can lose its scores to the removed-membership drop

- **Noted:** 2026-11-25 — the second review of #295 (fix/pulled-membership-keeps-delete)
- **Theme:** sync-robustness
- **Area:** app
- **Blocks release:** no — it needs a restored database, a refusal of only part of its batch, and a player who had been removed from that game

Since #295, `SyncStore._applyScore` drops a pulled score (`_skip`) when its player has no live
membership in the game but has a tombstoned one. It does not wait in `sync_inbox`. That is
sound only while a membership added back always reaches the log before its scores. A
device's push sorts memberships before scores (`_rank`), so that holds for a normal push.

A `lamport_reused` refusal breaks the order. A database restored from a backup pushes a
batch: a re-added membership (U2) and a score of it. The server refuses U2 with
`lamport_reused`, because its lamport was used before the backup was restored, and accepts
the score, whose lamport was not. The client stamps U2 again and pushes it in the same
pass (`SyncEngine`, `lamport_reused`), so the log now holds the score **before** U2.

Another device that removed that player earlier pulls the score first. It finds a tombstone
and no live membership, and drops the score for good. U2 arrives next and is inserted
without it. The device that typed the score still shows it.

**Fix (proposed):** keep the score waiting (`'game_player'`, quarantined) instead of
dropping it when its `client_lamport` is higher than the version of the delete that made the
tombstone. A stale score of the removed membership predates that delete. A score of a
membership added back after it does not. The inbox replay then attaches it once U2 is
applied. Or have the engine hold back a batch's later deltas of a parent re-stamped
`lamport_reused` until that parent is accepted.

**Acceptance:**
- A store test: a tombstoned membership, then a score with a lamport above the delete's, then
  the added-back membership. The score ends attached to the new membership.
- A store test: a score with a lamport below the delete's is still dropped, not queued. This is
  the existing `sync_store_test.dart` test "a score pulled for a removed membership is dropped,
  not kept for one added back", with its score stamped below the delete (it is above today).
