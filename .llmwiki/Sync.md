# Sync

> Scope: the offline-first sharing protocol. Server-side is done; the Flutter client is not.
> Related: [[Api]] · [[SchemaV9]] · [[Backend]] · [[KnownLimits]]
> Updated: 2026-09-13

## Facts

**Status: the backend is complete and tested. There is no client.** `sync_service.dart` and
`backend_client.dart` do not exist on disk, and nothing in `lib/` writes to `outbox`. The
schema is ready and waiting — see [[SchemaV9]].

> **Status: Outdated** (2026-09-09) — "complete and tested" overstates one area. The
> endpoints, dedup, round conflicts and the WebSocket are implemented and covered; the
> **conflict-resolution branch is neither what this page describes nor tested at all**.
> See the block under **Model** below, and the gap noted in [[Testing]].
>
> **Status: Outdated** (2026-09-13) — the conflict branch is tested now: row-level LWW, the
> loser dropped whole, ties broken by `origin_device_id` (`backend/tests/test_sync.py`).

### Model

An append-only `change_log` table on the server. Conflicts resolve **Last-Write-Wins per
field**, ordered lexicographically by `(client_lamport, origin_device_id)`.

> **Status: Outdated** (2026-09-09) — the server has never resolved conflicts per field.
> It resolves them **per row**. `backend/app/routes/sync.py:184-199` compares the incoming
> `(client_lamport, origin_device_id)` against the highest pair already in `change_log`
> for that `entity_uuid` and, when the incoming delta loses, drops it whole and answers
> `merged_lww` — nothing of it is written. The comment at `sync.py:184` says so outright:
> per-field would need a `field_versions` table, and there is none.
>
> What holds: **one writer wins the entire entity**. Two concurrent edits to *different*
> fields of the same row do not merge; the loser is discarded. The ordering rule itself is
> unchanged — lexicographic on `(client_lamport, origin_device_id)`.

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

> **Status: Outdated** (2026-09-09) — step (c) is written against per-field LWW, which the
> server does not implement. A client built from this sketch would apply a merge rule the
> server does not share and would diverge from it silently. The rule to write against is
> the row-level one: apply the delta when `(delta.client_lamport,
> delta.origin_device_id)` is greater than the pair last applied for that entity, and
> discard it entirely otherwise. This is client design, not an implemented fact — there is
> no client.

### WebSocket — signal only

> **Status: Outdated** (2026-09-09) — this page described `Authorization: Bearer
> <device_token>` at handshake, which the code never did. Browsers cannot set headers on a
> WebSocket handshake at all. The credential went in the query string until it was replaced
> by the ticket flow below.

Two steps. `POST /sync/ws-ticket` carries the device token in the Authorization header,
where it works, and returns a single-use ticket with a 60 s TTL. The client then opens
`/sync/stream?ticket=<value>`. The ticket is redeemed — and destroyed — before the
handshake is accepted, so the long-lived credential never reaches a URL and an
unauthenticated peer gets nothing but a 1008 close.

The server pushes exactly `{"type": "new_seq", "server_seq": N}`; the client reacts by
calling `/sync/pull`. Every 30 s of silence it sends `{"type": "ping"}` and re-checks that
the device is still not revoked, closing the stream if it is. No server-side buffer, so
reconnection is safe — fetch a fresh ticket, then reconnect. Backoff is exponential 1s, 2s,
4s … capped at 60s; on reconnect `since_seq` recovers whatever was missed.

Tickets live in process memory (`backend/app/services/ws_ticket.py`), which is one more
reason production runs a single uvicorn worker.

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

  > **Status: Outdated** (2026-09-09) — recorded as a decision, never implemented. In this
  > exact example the code drops one of the two edits (`merged_lww`) instead of merging
  > them. The intent still stands, but it is **open design, not behaviour**, until a
  > `field_versions` table exists. Nothing guards the gap either: `merged_lww` appears
  > nowhere under `backend/tests/`, so the branch that decides a conflict has no test.
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
