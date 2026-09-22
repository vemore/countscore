# A type v19 re-keys, while it is linked to the group by name, can stop syncing for good

- **Noted:** 2026-09-22 — independent review of #205 (fix/builtin-key-rekey, schema v19)
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no — the owner's three re-keyed rows (Skyjo, 6 qui prend, Yam's) were in
  no group in the 2026-09-19 backup; the case needs a group holding a keyless remote X and a
  keyed remote Y of the same built-in under different names

`applyV19` gives a keyless local row R its `builtin_key`. If R is linked to a keyless remote X
(linked by name), its capture trigger pushes X with the key. When the group already holds a
live keyed row Y, the server answers `builtin_key_taken`; `sync_engine.dart` `_resolve`
supersedes the delta and pulls. The pull relinks R to Y (`_applyGameType`, key match +
`INSERT OR REPLACE` on `group_links`) **only if Y has not been pulled yet**. If Y was pulled
earlier and linked to another local row, the pull brings nothing: R stays on X, and every later
push of R carries the key and is superseded silently — its edits never reach the group.

Second effect once R is relinked to Y: a later pulled delta for X matches R by name, and
`INSERT OR REPLACE` flips the link back to R↔X; pulled games pointing at the other remote wait
in `sync_inbox` (`sync_store.dart` around `:878`).

**Fix:** to be designed. Options: on `builtin_key_taken` for a `game_type`, when the pull
brings nothing, relink R to the group's keyed row by querying it (or drop the key from R's
payload for that group); make `_applyGameType`'s name fallback skip a local row already linked
to a different remote in that group.

**Acceptance:**

- A sync test with a group holding keyless X and keyed Y (already pulled, linked to another
  local row), where v19 keys R↔X: R's later edits reach the group, or are refused with a
  visible reason — never superseded silently.
- A pulled delta for X after R↔Y does not flip the link back.
