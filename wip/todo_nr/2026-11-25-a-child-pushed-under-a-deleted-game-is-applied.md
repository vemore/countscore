# A round, score, membership or analysis pushed under a deleted game is applied

- **Noted:** 2026-11-25 — test/sync-adversarial-api
- **Theme:** sync
- **Area:** backend
- **Blocks release:** no

*A delete wins* (`.llmwiki/Sync.md`) is enforced on the entity itself only. `_check_parents`
(`backend/app/routes/sync.py`) asks that a parent exist in the caller's group, not that it be
live, and `_apply_game_player` does not look at `games.deleted_at` either. Observed on SQLite:
`game` G, `player` P, `delete` G, then a `round` and a `game_player` under G, all in one push →
five `applied`. The rows are written under a tombstone and logged, and every device pulls them.

The race is narrow — a pass pulls before it pushes, and a pulled game delete drops the
device's pending outbox rows for its children — but two devices of a group hit it when one
deletes a game while the other has an unsynced round of it. Nothing crashes: the rows sit under
a dead game everywhere, out of sight, and the group comment endpoint already refuses a deleted
game.

**Fix:** answer `merged_lww` for an upsert whose game (directly, or through its round) is
tombstoned, as for an upsert on a tombstone itself — the delete won, nothing is written, and
the app already treats `merged_lww` as done. `rejected` / `parent_missing` would make the app
retry once and then count a rejection the user can do nothing about.

**Acceptance:**
- A round, a score, a `game_player` and a `game_analysis` pushed under a tombstoned game each
  answer `merged_lww` and write no row (`backend/tests/test_sync_adversarial.py`).
- The same pushes under a live game still answer `applied`.
