# Sync

> Scope: the offline-first sharing protocol — server and Flutter client.
> Related: [[Api]] · [[SchemaV10]] · [[Backend]] · [[KnownLimits]]
> Updated: 2026-09-24

## Facts

**Status: the backend is complete and tested. There is no client.** `sync_service.dart` and
`backend_client.dart` do not exist on disk, and nothing in `lib/` writes to `outbox`. The
schema is ready and waiting — see [[SchemaV10]].

> **Status: Outdated** (2026-09-13) — the client exists: `lib/services/sync/` and
> `lib/providers/group_provider.dart`, described under **The client** below.

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

### Push, as the server applies it (since 2026-09-13)

`backend/app/routes/sync.py`, module docstring and `push`:

1. The group row is read `FOR UPDATE`: pushes to one group run one at a time, and
   `groups.last_server_seq` hands out each `server_seq` once. `(group_id, server_seq)` is
   unique in `change_log`.
2. Dedup on `(origin_device_id, client_lamport)` → `duplicate`, with the original seq.
3. Each remaining delta runs in **its own savepoint**. A rejection — or an `IntegrityError`
   the pre-checks missed — undoes that delta alone; the rest of the batch keeps its rows,
   its log entries and its seqs. Rejected deltas consume no seq.
4. **Group scoping.** An existing uuid of another group is `rejected` (`not in group`);
   every parent a payload names must be in the caller's group (`parent_missing`).
5. **A delete wins.** An upsert on a tombstoned row, or on a uuid the group's log holds a
   delete for, is `merged_lww` and writes nothing, whatever its lamport. A payload cannot
   set `deleted_at`, `group_id`, `id`, `created_at` or `updated_at`.
6. Unique rules (round number, score slot, player and game-type names, one analysis per
   game) apply to **live rows only** and are checked before the write, so a clash comes
   back as a stable reason code rather than a driver error — codes in [[Api]].
7. The log stores the payload's known client columns only; that is what other devices pull.

Synced entities: `player`, `game_type` (with `rules` and `rules_slug` since v13, `builtin_key` since v14), `game`,
`game_player`, `round` (with `comment`), `score`, `game_analysis`. `game_player` still has
no uuid and is hard-deleted.

### A built-in game type travels by key, not by name (since 2026-09-16)

The `game_type` payload carries **`builtin_key`** alongside `name`
(`lib/services/sync/sync_store.dart`, `case 'game_type'`), and the server stores it
(`backend/app/models/game.py`, revision `0004_game_type_builtin_key`).

A built-in type's `name` is localized, so it is not its identity: two devices set to
different languages hold "Autre" and "その他" for one and the same type. Three things follow.

- **The group link is derived from the key.** `linkedGameTypeRemoteUuid`
  (`lib/services/sync/sync_ids.dart`) hashes `game_type_builtin:<key>` instead of the
  normalised name, so both devices mint the same server uuid before either has pulled. A
  type with no key still hashes its name, exactly as a player does.
- **An incoming delta matches on the key first**, then falls back to the name
  (`_applyGameType`). That is what links a device's own built-in row to the group's, whatever
  the two call it.
- **One live row per `(group_id, builtin_key)`** — a partial unique index, and a
  `builtin_key_taken` rejection so a clash is a reason rather than a driver error
  (`_check_unique`, `backend/app/routes/sync.py`). `unique(group_id, name)` is unchanged:
  a user's own types still collide by name. The client **resolves** that reason rather than
  rejecting it — `markSuperseded` then a pull, like `score_exists` — because the engine's
  default is terminal, and a rejected `game_type` would leave every game that references it
  pushing a `game_type_id` the server never created, stalling on `parent_missing` for good
  (`sync_engine.dart`, `test/sync/sync_engine_resolve_test.dart`).

Last-writer-wins on `game_types.name` is therefore harmless for a built-in row — nothing
reads it while the key is set. See [[SchemaV10]] and [[I18n]].

> **`is_default` is pushed but never applied.** The payload carries it
> (`sync_store.dart`, `case 'game_type'`) and the server stores it, but `_applyGameType`
> inserts every received row with `isDefault: 0`, so the value never round-trips and a
> built-in type acquired from a group has always carried 0. It is a historical column that
> nothing reads; `builtin_key` is the identity. [[SchemaV10]] settles it, and no back-fill
> written since v14 keys on it — which is what let the v18 step repair the `rules_slug` the
> pre-1.3.1 editor wiped, NULLs it had already pushed to the group included.

> A group that was already sharing *before* this change keeps its existing name-derived
> links (`_ensureLinks` only links rows it has not linked yet). Those groups converge on the
> next pull instead, through the key match in `_applyGameType`.

- `client_lamport` is a monotone integer per device, a logical clock. On write:
  `lamport = max(local_max, last_server_seq_received) + 1`.
- **Idempotence**: the server deduplicates on `(origin_device_id, client_lamport)`. A
  network retry of the same delta is a no-op.

### A wiped `rules_slug` does not travel (since 2026-09-20)

`rules_slug` is the one game-type column whose **null is not a value**. Nothing in the app
clears it on purpose — *Restore the default* (`game_rules_screen.dart`) clears `rules`, not
the slug — so a null there is always damage from the pre-1.3.1 editor. Three rules in
`sync_store.dart` keep that damage from spreading, and from undoing the v18 repair:

- **Push** (`case 'game_type'`): the `rules_slug` key is **omitted** when the local value is
  null, rather than sent as null. The server keeps a column whose key is absent
  (`_client_payload` filters on key presence, not on value), so an absent key means "no
  opinion" end to end.
- **Pull, update** (`_applyGameType`): `rules_slug` is taken only when the incoming value is
  non-null, instead of the `containsKey` test every other column uses. `rules` keeps
  `containsKey`, because the user does clear it.
- **Pull, insert**: a received built-in type with a null slug is inserted with
  `defaultRulesSlugs[builtin_key]` — the same derivation `applyV16`/`applyV18` make, imported
  rather than copied. The migration chain will not run again, so this is the only repair left
  for a device that joins a group before a healthy one has pushed the slug back.

A non-null slug still travels and still wins: a type the user **renames** loses its
`builtin_key` (`isBuiltinRename`, `lib/utils/game_type_name.dart`), and the slug is then the
only thing carrying its rules between devices.

> **Rejected: dropping `rules_slug` from the payload** and deriving it on receipt. It would
> make the corruption non-contagious in one line, but it is a contract change between
> devices, and it costs a renamed type its rules — exactly the case the column exists for
> ([[SchemaV10]]). Weighed twice now, in
> `wip/2026-09-20-wiped-rules-slug-is-never-restored` and in
> `wip/2026-09-20-a-null-rules-slug-travels-and-undoes-the-v18-repair`.

Healing the group needs nothing more: the v18 `UPDATE` on a linked row fires the v11 capture
trigger, so a repaired device pushes its restored slug and overwrites the null the server
holds. `test/sync/sync_store_test.dart` covers the five cases.

The v19 step does the same with a `builtin_key` it gives back ([[SchemaV10]]): a linked row
pushes its new key and slug. Where the group already holds a live row with that key the
server answers `builtin_key_taken`, and the client supersedes the delta and pulls — which
relinks the local row only if the group's keyed row had **not** been pulled yet. If it had
been, and was linked to another local row, the pull brings nothing and the row's later
pushes are superseded for good. No test covers the v19 path through sync; the owner's three
rows were in no group in the 2026-09-19 backup.
`wip/todo_nr/2026-09-22-a-rekeyed-type-linked-by-name-can-stop-syncing.md`.

### The client (since 2026-09-13)

Sync runs only while a server URL is configured **and** the device holds a device token —
the user's design. One group per device.

**Joining.** Settings → Group creates a group (`POST /groups`) or joins one with a pasted
`share_token` (`POST /groups/join`). The device token and share token go to
`flutter_secure_storage` (`sync_credentials.dart`); group id, name and device id go to
`sync_state`. Leaving revokes the device when the server answers, then `SyncStore.leave`
turns every shared row back into a local one and empties `outbox`, `group_links`,
`entity_versions`, `sync_inbox` and `sync_state`. Tombstones with nobody left to inform go
for good, game types among them: a game-type tombstone no game points at is deleted, or it
would hold its `builtin_key` reserved against the seed for ever. Clearing the server URL
while in a group asks, then leaves.

**Removing another device.** Settings → Group → *Devices* (`group_devices_sheet.dart`) lists
`GET /groups/me/devices`, marks the owner, and — on the owner only — offers a revoke and a
hand-over (*Make owner*, `PUT /groups/me/owner`) on every device but this one; this one leaves
instead. A member that is not the owner sees the list and no action, with one exception: when
the list reports the **owner's** row `dormant` — unseen for `GROUP_OWNER_DORMANT_DAYS`, which
is what an uninstalled app looks like — that row offers *Claim ownership*
(`POST /groups/me/owner/claim`, key `group_device_claim_<id>`). The server decides, so a 409
(`GroupActionError.ownerActive`) is shown as a message and `isOwner` is not flipped on a
guess; a server that predates the field sends no `dormant` and the action never appears.
Creating a group says in one line that the role lives on this device and can be handed over
(`groupCreatedOwnerExplain`). Settings → Group hides *New code* from a member. `GroupProvider.isOwner` is held in memory, never in the database:
true after creating, false after joining, then refreshed from `owner_device_id`
(`GET /groups/me`) on every start and resume, from `is_owner` whenever the list loads, and
dropped on any 403. A server that predates owners sends neither field; every device then
keeps the actions, as before. `GroupProvider.revokeDevice` stores the rotated `share_token` the server returns, so
the section shows the new invite code at once. The revoked device learns of it on its next
request: a 401, shown as `SyncStatus.unauthorized` (its open stream closes with 1008 at the
next push to the group or the next idle heartbeat, whichever comes first — see *WebSocket*). Its local copies of the games stay where they are.

**The nickname.** A device's name in the group (`devices.label`) is what its siblings see in
the devices list. The create and join dialogs ask for it first (`group_nickname_field`,
`groupNicknameLabel` with the `groupNicknameHint` helper), empty, and OK stays disabled until
every field holds a non-blank value; the values go out trimmed. Settings → Group shows it
(`groupNicknameCurrent`) with an edit button (`group_nickname_edit`) that reuses the same field
and calls `GroupProvider.renameDevice`, i.e. `PATCH /groups/devices/me`. The provider holds the
label in memory only: set on create and join, from the rename's answer and from this device's
row whenever the devices list loads, unless a rename completed while that list was in flight
(a counter bumped by each rename). After a restart `refreshDeviceLabel` reads the list on
start and resume, after each successful sync while the label is still unknown, and when the
section opens, so an offline start does not leave it unknown. The dialog fields stop at 64
**code points**, as the server counts (`maxLength` would count grapheme clusters); an
unchanged nickname sends nothing; a 422 on rename shows the generic server error, since no
existing string says "invalid name". A rename changes no synced row.

**Comment settings and usage.** Settings → Group → *Comments and usage*
(`group_settings_screen.dart`) shows the group's `comment_style` and `comment_language` from
`GET /groups/me` and changes them with `PATCH /groups/me/settings` — every member may — and
the month's spending from `GET /groups/me/usage`. `BackendClient.updateGroupSettings` has no
budget parameter, so the app never sends `monthly_budget_cents`, owner or not: the budget is
the owner's on the server (403 otherwise) and the app offers no control for it. These
settings shape the analysis of a **shared** game, which goes through the group-scoped
`POST /groups/me/games/{id}/comments` (since 2026-09-19, [[Api]]): billed to the group, so it
moves the usage on that screen, written in the group's language, and in the group's style
when the device has never picked a voice. `GroupProvider.gameAnalysis` answers a 404 (the
share not pushed yet) with one sync and one retry; `GameAnalysisScreen` falls back on the
stateless endpoint if the server still does not hold the game. An unshared game, or one
shared with a group this device has left, keeps the stateless `/comments/game-analysis`.

**Sharing is per game.** On by default for a new game while in a group (switch on the
create screen), or later from the board menu; never undone. `SyncStore.shareGame` sets
`group_id` on the game and its children. Player names the server would refuse
(`isSyncablePlayerName`, mirroring `is_valid_player_name`: letters with their combining
marks, digits, space, `-`, `'`, `.`) block sharing up front.

**Capture — SQLite triggers, not repository code** (`sync_schema.dart`, schema v11). Every
INSERT/UPDATE on a row with `group_id` set appends `(entity_type, entity_uuid, op)` to
`outbox`, `op` read from `deleted_at`; players and game types are captured once they have a
`group_links` row. Rows inserted under a shared game inherit its `group_id` through
`*_inherit` triggers, so the repositories stay group-blind. `sync_flags.suppress` is raised
while pulled deltas are applied, so nothing received is sent back.

**Push** (`SyncStore.preparePush`, `SyncEngine`). Outbox rows are coalesced per entity, the
payload is built from the row as it is *now*, and a lamport is stamped from
`sync_state.last_lamport`; a prepared row keeps its lamport and payload until the server
answers, so a retry is a `duplicate`, never a second apply. Players and game types are linked
first: their server uuid is `uuid5(group_id, "<type>:<normalised name>")`, so every device
computes the same identity for "Alice" and the server's unique name never collides. Batches of
100, parents first (`game_type` → `player` → `game` → `game_player` → `round` → `score` →
`game_analysis`). Strings are clipped to the server bounds. A player's delete is
not sent: removing a player from this device's catalogue is not a group event. **A game
type's delete is** (since 2026-09-20). Game types carry no `group_id` — they reach a group
through `group_links` — so `DriftGameTypeRepository.delete` tombstones a type that has a
link and hard-deletes one the group never saw (`_isLinked`,
`lib/repositories/drift/drift_repositories.dart`); the capture trigger, which tests the same
link, turns the stamp into a `delete` delta with an empty payload. Tombstoned games keep their
`gameTypeId` when the type is tombstoned (the row stays, and rewriting them would enqueue a
second `delete` for each); only the hard delete clears it first, with capture suppressed,
since no foreign key is enforced on `gameTypeId`: Drift declares none, and on native, where the
sqflite schema declares `ON DELETE SET NULL` (`database_service.dart`), `PRAGMA foreign_keys` is
off (since 2026-09-24).

| Server answer | Client does |
|---|---|
| `applied`, `duplicate` | done; its lamport becomes the entity's known version |
| `merged_lww` | done; the winner arrives with the next pull |
| `round_number_taken` | pull, move the round to max+1, push again; `RoundRenumbered` → snackbar |
| `score_exists`, `analysis_exists` | done; the pull adopts the server's uuid for that cell |
| `parent_missing` | retried once, rejected the second time |
| anything else | rejected, counted in Settings |

**Pull** (`SyncStore.applyPulled`, one transaction per page). Own deltas skipped. Upserts
are applied only when `(client_lamport, origin_device_id)` beats `entity_versions`; a delete
always applies, tombstones the row and its children, and drops pending outbox rows for it.
A pulled player or game type links to the local one of the same name or is created. A
pulled `game_type` delete tombstones the linked local row — unless a live game still plays
it, which may be a local game the group never saw, and then the row stays (`_applyGameType`).
An upsert for a type this device has already tombstoned is ignored, as on the server. A delta
whose parent is not local yet waits in `sync_inbox`, replayed after every page. The local
lamport is raised past every lamport seen.

**A game deleted elsewhere while open** closes its board: `GameProvider.refreshFromSync`
notices the current game is gone and the board pops with a snackbar naming it.

**Triggers** (`GroupProvider`): local writes (Drift table updates, debounced 1 s), the
WebSocket `new_seq` signal (`sync_stream.dart`, fresh ticket per connection, backoff 1 s →
60 s), app resume, a 60 s poll, and "Sync now". A 401 shows "no longer accepted"; no answer
shows "offline" and keeps the outbox.

### Write path on a device

> **Status: Outdated** (2026-09-13) — a design sketch. The client captures with triggers
> rather than in `Repository.upsert`, stamps lamports at push time rather than at write time,
> and handles four statuses (`duplicate` too). See **The client** above.

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
calling `/sync/pull`. Every 30 s of silence it sends `{"type": "ping"}`. Before every frame —
`new_seq` or `ping` — it re-checks that the device is still not revoked (one primary-key read,
`_is_revoked`) and closes the stream with 1008 if it is, so a revoked device gives its
`MAX_STREAMS_PER_DEVICE` slot back at the group's next push. Until 2026-09-14 the check ran
on the idle heartbeat only, which a busy group never reaches. No server-side buffer, so
reconnection is safe — fetch a fresh ticket, then reconnect. Backoff is exponential 1s, 2s,
4s … capped at 60s; on reconnect `since_seq` recovers whatever was missed.

Tickets live in process memory (`backend/app/services/ws_ticket.py`), which is one more
reason production runs a single uvicorn worker.

**One LISTEN connection for the whole process** (`backend/app/services/notify.py`, since
2026-09-13). Every stream used to open its own asyncpg connection, so one device could
exhaust Postgres `max_connections`. A module-level broker now holds a single connection
(`application_name` `countscore-listen`), adds a channel listener for the first stream of a
group and removes it after the last, and fans each `NOTIFY` out to one in-process queue per
stream. If that connection drops, every stream is closed with 1012 and the client's usual
reconnect-then-pull recovers; the next stream opens a new connection. On top of that a
device may hold at most `MAX_STREAMS_PER_DEVICE` (3, for PWA tabs) streams — the next is
closed with 1013 before `accept()`. The counter is process memory too (`_open_streams` in
`app/routes/sync.py`).

### Server schema

`backend/app/models/*.py` is the source of truth, `alembic/versions/` the exact DDL
(`0001_initial`, `0002_sync_contract`). Tables: `groups` (with `last_server_seq`),
`devices`, `players`, `game_types`, `games`, `game_players`, `rounds`, `scores`,
`game_analyses`, `comments` (with `scores_hash`, `prompt_hash`, `tokens_in/out`,
`cost_cents`), `change_log`, `rate_limits`. Colour columns are `BIGINT`.

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
- **A game type's delete travels, a player's does not (2026-09-20).** Until then
  `game_types` was the one table whose delete had no shared branch at all: the row was
  removed outright even inside a group, so nothing ever told the other devices, and the next
  pull could hand the type back. The two are not symmetric. A player is a name in *this*
  device's catalogue and its shared memberships tombstone on their own; a game type names
  what the group plays, and it can only be deleted once no live game uses it — the same
  guard the other devices apply before following the delete.
- **A delete wins over a concurrent edit (2026-09-13).** Chosen with the user for the
  client design: deleting a shared game removes it for the whole group. Row-level LWW alone
  would let a late upsert with a higher lamport resurrect a game somebody deleted, which
  reads as a bug to everyone at the table. Tombstones therefore also free their unique
  slots — otherwise a deleted round 5 would block the next round 5 forever.
- **Stable reason codes instead of "integrity constraint violation" (2026-09-13).** The
  client must renumber on a round clash and adopt the server's row on a score clash; it
  cannot tell those apart from one generic string, and parsing driver messages is exactly
  what the reason field exists to avoid.
- **Change capture by SQLite trigger (2026-09-13).** Enqueuing from each repository method
  would have touched about twenty methods, each one a way to forget a write (a rename, a
  colour, a round comment). A trigger sees every write however it is made, and the
  suppress flag keeps pulled changes from echoing. The price is SQL shared by two engines,
  which `sync_schema.dart` keeps in one list.
- **Payload built at push time, not at write time (2026-09-13).** Ten score edits to one
  cell send one delta with the last value, and a delta can never describe a row that has
  since changed again.
- **A built-in game type merges by key, a user's by name (2026-09-16).** The deterministic
  uuid below works because both devices compute it from the same string. That stopped being
  true for game types the moment their names became localized, so built-in types hash their
  `builtin_key` instead. Translating the rows in place was the alternative and it fails the
  same way: two devices, two locales, two names, two rows.
- **Players merge by name through a deterministic uuid (2026-09-13).** Chosen with the user
  over separate group players: stats stay keyed on the local global player, and two devices
  that both have "Alice" converge without a join-time reconciliation step.
- **Local and shared games coexist on one device.** `group_id TEXT NULL`; NULL means local
  and the sync worker only ever sends non-NULL rows. Existing users' games stay local with
  zero friction, and joining a group risks nothing. Multi-group per device was deferred on
  UX grounds, not schema ones.
- **Group `share_token` to join once, then a per-device token.** Losing a phone revokes one
  device instead of forcing everyone to rejoin, and the log says which device wrote what. A
  leaked share link can be rotated without re-authenticating devices already in. Full
  email/password auth was rejected as overkill for family scorekeeping and needless attack
  surface.
