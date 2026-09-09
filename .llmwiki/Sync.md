# Sync

> Scope: the offline-first sharing protocol. Server-side is done; the Flutter client is not.
> Related: [[Api]] · [[SchemaV9]] · [[Backend]] · [[KnownLimits]]
> Updated: 2026-09-09

## Facts

**Status: the backend is complete and tested. There is no client.** `sync_service.dart` and
`backend_client.dart` do not exist on disk, and nothing in `lib/` writes to `outbox`. The
schema is ready and waiting — see [[SchemaV9]].

### Model

An append-only `change_log` table on the server. Conflicts resolve **Last-Write-Wins per
field**, ordered lexicographically by `(client_lamport, origin_device_id)`.

- `client_lamport` is a monotone integer per device, a logical clock. On write:
  `lamport = max(local_max, last_server_seq_received) + 1`.
- **Idempotence**: the server deduplicates on `(origin_device_id, client_lamport)`. A
  network retry of the same delta is a no-op.

### Write path on a device

```
1. UI → Provider → Repository
2. Repository.upsert(entity) inside one Drift transaction:
   a. UPDATE/INSERT the business table
   b. IF entity.group_id != NULL:
        INSERT INTO outbox (entity_type, entity_uuid, op, payload, client_lamport)
3. Sync worker drains the outbox: POST /sync/push, batches up to 100 deltas
4. Per-delta response:
   applied | merged_lww  → UPDATE outbox SET sent_at = now()
   rejected             → force refresh + notify the UI
```

### Read path

```
1. At startup, every N seconds, or on a WebSocket signal:
   GET /sync/pull?since_seq=<sync_state.last_server_seq>&limit=500
2. Per delta:
   a. skip if origin_device_id == self (already applied locally)
   b. look the entity up by uuid
   c. apply LWW per field: write if delta.client_lamport > local.last_lamport_per_field
   d. sync_state.last_server_seq = max(current, delta.server_seq)
```

### WebSocket — signal only

`/sync/stream`, `Authorization: Bearer <device_token>` at handshake. The server pushes
exactly `{"type": "new_seq", "server_seq": N}`; the client reacts by calling `/sync/pull`.
No server-side buffer, so reconnection is safe. Backoff is exponential 1s, 2s, 4s … capped
at 60s; on reconnect `since_seq` recovers whatever was missed.

### Server schema

`backend/app/models/*.py` is the source of truth, `alembic/versions/0001_initial.py` the
exact DDL. Tables: `groups`, `devices`, `players`, `game_types`, `games`, `game_players`,
`rounds`, `scores`, `comments` (with `scores_hash`, `prompt_hash`, `tokens_in/out`,
`cost_cents`), `change_log`, `rate_limits`.

## Decisions & History

- **Hand-written delta-log over CRDTs or a managed sync product.** Roughly 500 LOC of
  backend and 500 of client, fully debuggable, and the log doubles as audit trail,
  WebSocket stream and history — three functions from one table. CRDTs (Automerge, Yjs)
  guarantee convergence mathematically but bring a steep learning curve, hard debugging and
  metadata overhead, a poor fit for structured data like scores. ElectricSQL and PowerSync
  are turnkey but mean a SaaS dependency or heavy infrastructure, and surrender control of
  the conflict model.
- **LWW per field, not per row.** Alice renames Bob while Charlie changes Bob's colour —
  both merge instead of one silently destroying the other.
- **The WebSocket carries a sequence number, not the payload.** Nothing to buffer, nothing
  to replay, and reconnection needs no special case: the client already knows its
  `since_seq`.
- **Simultaneous rounds: first wins, second is rejected explicitly.** `UNIQUE(game_id,
  round_number)` on the server. Simple to implement and intuitive once surfaced properly
  ("Round 5 was entered on another device — here are its scores"). The consequence is that
  the client outbox must handle three per-delta statuses: `applied`, `merged_lww`,
  `rejected`.
- **Local and shared games coexist on one device.** `group_id TEXT NULL`; NULL means local
  and the sync worker only ever sends non-NULL rows. Existing users' games stay local with
  zero friction, and joining a group risks nothing. Multi-group per device was deferred on
  UX grounds, not schema ones.
- **Group `share_token` to join once, then a per-device token.** Losing a phone revokes one
  device instead of forcing everyone to rejoin, and the log says which device wrote what. A
  leaked share link can be rotated without re-authenticating devices already in. Full
  email/password auth was rejected as overkill for family scorekeeping and needless attack
  surface.
