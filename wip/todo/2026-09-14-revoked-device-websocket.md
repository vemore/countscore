# A revoked device keeps its WebSocket open while the group is busy

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
