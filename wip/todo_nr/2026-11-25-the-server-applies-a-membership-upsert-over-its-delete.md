# The server applies a membership upsert over its delete, and re-creates the player in the game

- **Noted:** 2026-11-25 — fix/pulled-membership-keeps-delete, the *merged_lww* real-server test
- **Theme:** sync-robustness
- **Area:** backend
- **Blocks release:** no — the devices keep the removal; only the server's own table is wrong

Every other entity follows "a delete wins" on push (`backend/app/routes/sync.py`,
`_apply_delta`: a tombstoned row or a uuid with a logged delete answers `merged_lww`). A
`game_player` does not: `_apply_game_player` keys it by `(game_id, player_id)`, hard-deletes it,
and applies every upsert — no LWW, no delete check — re-creating the row. In the *merged_lww*
test of `test/sync/sync_multi_group_backend_test.dart`, Y removes Alice, then X's colour edit of
her (lamport 60, against the delete's 11) is answered `applied`, and the server's
`game_players` holds Alice again (checked in Postgres, 2026-11-25). The devices no longer
show her (`_applyGamePlayer`, since this branch), but `backend/app/routes/comments.py` reads
that table for the group commentary, so the LLM is told she plays.

The reverse also holds: a late delete of a membership removed and added back since (the
client mints a new uuid for the re-add, schema v24) hard-deletes the added-back row on the
server, while every device keeps it.

**Fix:** give the server the client's identity for a membership. Either check the log by
`entity_uuid` in `_apply_game_player` — an upsert of a uuid with a logged delete is
`merged_lww`; a delete removes the row only when the last upsert logged for the pair has that
uuid — or store the uuid on `game_players` (an expand-only revision: a nullable column) and
tombstone instead of deleting. The first needs no migration.

**Acceptance:**
- A `game_player` upsert of a uuid the group's log holds a delete for is answered
  `merged_lww`, and the server's `game_players` does not hold the pair afterwards.
- A delete of a membership's old uuid, logged after the pair was added back under a new one,
  leaves the server's row in place.
- `backend/tests/test_sync.py` covers both.
