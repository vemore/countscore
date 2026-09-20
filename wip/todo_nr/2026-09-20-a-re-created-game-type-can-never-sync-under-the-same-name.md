# A game type re-created under a name the group once deleted can never sync again

- **Noted:** 2026-09-20 — while tombstoning game-type deletes (`fix/game-type-tombstone`)
- **Theme:** sync
- **Area:** app
- **Blocks release:** no

A player's and a game type's identity in a group is **derived from the name or the built-in
key**, not minted: `linkedGameTypeRemoteUuid` hashes `game_type_builtin:<key>` or the
normalised name (`lib/services/sync/sync_ids.dart`), which is what lets two devices converge
on "Belote" without talking first. Combine that with *a delete wins* and the identity is
spent once it is deleted:

- `_ensureLinks` refuses to mint a link whose `remote_uuid` another local row already holds
  (`_link`, `lib/services/sync/sync_store.dart`), and the deleted type's link is still there.
  The new local type is therefore never linked, never captured, never pushed.
- Even if it were, the server answers `merged_lww` for ever: `_was_deleted`
  (`backend/app/routes/sync.py`) finds the delete in the group's `change_log` and refuses
  every later upsert of that uuid, whatever its lamport.

So: delete "Belote" in a group, create "Belote" again, and the second one is local-only on
the device that made it, silently. Games played with it push a `game_type_id` the server does
not have and stall on `parent_missing`, which the engine retries once and then rejects.

The same shape applies to a player, with one difference: a player's delete is not pushed
(`_build`, `case 'player'`), so no delete ever reaches the group's log — only the stale
`group_links` row blocks the relink, and `leave` clears that. A game type's delete does reach
the log since 2026-09-20, so the server half is real.

Not urgent: it needs a group, a deletion and a re-creation under the same name, and the sole
user of production is on one device.

**Fix:** decide how a deleted deterministic identity is retired. Candidates: drop the
`group_links` row when the delete is acknowledged and salt the next hash for that name
(`game_type:<name>#2`), so a re-created type mints a fresh uuid; or stop deriving the uuid
for a *user's* type and keep derivation for built-in keys only, where the key is genuinely
stable. Either way `_link` must stop failing silently — the new row is currently dropped
with no trace.

**Acceptance:**
- A game type deleted in a group and then re-created under the same name is pushed and
  reaches the other device.
- Games that use the re-created type do not stall on `parent_missing`.
- A built-in type still links by key, so two locales converge as they do today
  (`test/sync/sync_ids_test.dart`).
