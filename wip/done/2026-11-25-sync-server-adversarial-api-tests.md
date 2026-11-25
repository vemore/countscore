# The sync API is tested on the nominal path, not against stale, replayed or hostile input

**Status:** done (2026-11-25) — closed by test/sync-adversarial-api. Every case has a test in
`backend/tests/test_sync_adversarial.py` (the Postgres-only ones at the end of
`test_sync_ws_integration.py`). Fixed on the way: a reused lamport with another payload is
rejected `lamport_reused` instead of `duplicate`; a value of the wrong JSON type, a lamport
or `since_seq` past BIGINT, a NUL byte or a lone surrogate is one rejected delta or a 422
instead of a 500; an unknown `entity_type` is one rejected delta instead of a 422 for the
batch; a player's `name_normalized` is derived by the server. The push cap is 500, not 100
as written below (the app batches 100). Client side: `wip/todo/2026-11-25-client-restamps-on-lamport-reused.md`;
found on the way: `wip/todo_nr/2026-11-25-a-child-pushed-under-a-deleted-game-is-applied.md`.

- **Noted:** 2026-11-25 — planning multi-group (`2026-11-17-belong-to-several-groups.md`)
- **Theme:** sync-robustness
- **Area:** backend
- **Blocks release:** no

`backend/tests/test_sync.py` and `test_sync_contract.py` cover the contract each rule was
written for. Several groups per install multiplies the ways a client can send what the server
did not plan for: a token of group A naming rows of group B, a restored backup replaying old
deltas, a rename that clashes in one group only. The user's requirement: the server must hold
whatever a client sends, and tests must prove it.

**Fix:** a pytest suite (`backend/tests/test_sync_adversarial.py`), one test per case, each
asserting the answer **and** that nothing else changed (no row written, no seq consumed, no
leak in a pull). Every case the suite finds broken becomes a fix in the same pull request, or a
`wip/` entry if it is large.
- **Cross-group:** a token of A pushing an uuid that exists in B (`not in group`); a payload
  whose parent (game type, player, game, round) is in B (`parent_missing`); a pull of A never
  returns B's deltas; a revoked device in A leaves the same install's device in B working; two
  device rows of one install pushing concurrently to A and B.
- **Replay / restored backup:** the same `(origin_device_id, client_lamport)` with a
  **different** payload. Today it answers `duplicate` and drops the new payload: a device
  restored from a backup re-stamps lamports already used and loses its new edits silently.
  Pin the behaviour, then decide (e.g. answer `lamport_reused` when the payload differs, and
  have the client re-stamp past it). Also: a lower lamport than stored (`merged_lww`), an
  upsert on a tombstone, a delete of an unknown uuid, delete then upsert in one batch.
- **Renames:** a player renamed onto a name held in the group (`name_taken`); renamed in a way
  that is free in A and taken in B; rename then delete; a game type renamed off its
  `builtin_key`.
- **Malformed input:** unknown `entity_type`, missing or extra keys, wrong JSON types, null
  required fields, bad uuids, strings past the bounds, numbers out of bounds, a batch over 100,
  an empty batch, the same entity twice in one batch, `since_seq`/`limit` negative or huge.
- **Membership:** leave then re-join (new device row) and re-push old games; a token of a group
  the server no longer has.

**Acceptance:**
- Every case above has a test in `backend/tests/`, green in CI.
- No case answers 500, writes a row it reports as rejected, or consumes a `server_seq` for a
  rejected delta.
- The lamport-reuse decision is recorded in `.llmwiki/Sync.md`.
