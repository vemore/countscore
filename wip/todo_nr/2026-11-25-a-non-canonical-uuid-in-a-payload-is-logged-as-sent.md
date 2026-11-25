# A parent uuid in a payload is accepted in any spelling and logged as sent

- **Noted:** 2026-11-25 — independent review of test/sync-adversarial-api (#291)
- **Theme:** sync
- **Area:** backend
- **Blocks release:** no

`_as_uuid` (`backend/app/routes/sync.py`) parses a payload's parent references
(`game_type_id`, `game_id`, `round_id`, `player_id`) with `uuid.UUID(str(value))`, which takes
braces, a `urn:uuid:` prefix, upper case and no dashes. The parent check passes, the row
stores the parsed uuid, but the log stores the payload **as sent** (`_logged_payload`), so a
pulling device gets `"{ABCD...}"` and cannot match it to the local row it knows as
`abcd-...`: the child waits in `sync_inbox` for a parent that never comes. Pre-existing; the
app sends the canonical lowercase form, so only a foreign client triggers it.

**Fix:** either refuse a uuid that is not canonical (`str(uuid.UUID(v)) != v` →
`parent_missing`), or log the canonical form, as the row stores it. Refusing is the smaller
change and keeps "the log holds what was sent".

**Acceptance:**
- A round whose `game_id` is upper case, braced, `urn:uuid:`-prefixed or undashed is
  answered as decided, and never logged in that spelling (`backend/tests/test_sync_adversarial.py`).
- The app's lowercase dashed uuids are still applied.
