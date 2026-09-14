# A revoked device keeps its WebSocket open while the group is busy

**Status:** done (2026-09-14) — closed by fix/revoked-device-stream. `_serve_stream` now
re-checks revocation before every frame (signal or heartbeat) and closes with 1008; covered by
a fast test and a Postgres integration test that revokes a device while its group pushes.

- **Noted:** 2026-09-14 — while adding the device list
- **Theme:** backend-sync
- **Area:** backend
- **Blocks release:** no — nothing leaks, a stream slot stays held

`POST /groups/me/devices/{id}/revoke` does not signal the device's open `/sync/stream`, which
re-checks `revoked_at` only in its idle heartbeat (`backend/app/routes/sync.py`,
`_is_revoked`, after 30 s without notification). While the group keeps pushing, the revoked
device keeps receiving `new_seq` signals (no data; `/sync/pull` answers 401) and holds one of
its `MAX_STREAMS_PER_DEVICE` slots.

**Fix:** re-check revocation on every signal (one primary-key read), or have the revoke route
notify a per-device close through the LISTEN broker in `app/services/notify.py`.
