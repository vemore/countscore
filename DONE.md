# DONE

Closed items, newest first. Moved out of `TODO.md` when they were finished, so that file
holds only open work. Nothing here is deleted — the reasoning behind a decision stays
readable after the fact.

---

## Backend review (hardening bundle): the Docker image runs as root, unlocked

**Status:** done (2026-09-14) — closed by `chore/backend-dockerfile-hardening`. The
`Dockerfile` has two stages. The builder runs `uv sync --locked --no-dev --no-install-project`
with a pinned `uv`. The runtime `python:3.13-slim` holds only that venv and the code, both
owned by root, with no apt packages, and runs as `USER app` (uid 10001). Size went from
600 MB to 271 MB. Checked against Postgres 17: `alembic upgrade head`, `/health`, the PWA
mount, and the compose healthcheck. A new `image` CI job builds it and checks non-root, no
compiler, no dev dependencies and read-only code. The other two bullets of the bundle (a
dependency scan, encrypted backups) stay in `TODO.md`.

- `backend/Dockerfile` runs as root, keeps `build-essential` in the final image, and
  installs from `pyproject.toml` — not from `uv.lock`, which only CI honours
  (`uv sync --locked`), so production resolves its own dependency set. Multi-stage build,
  a `USER`, and `uv sync --locked --no-dev`.

## The two-device sync test does not run in CI

**Status:** done (2026-09-14) — closed by `chore/ci-sync-two-devices`. A fourth CI job,
`sync`, runs a `postgres:17-alpine` service, `alembic upgrade head`, uvicorn with the raised
limits, then the test with `SYNC_TEST_REQUIRED=true`, which makes a missing URL fail instead
of skip. Noted 2026-09-13, while writing `test/sync/sync_two_devices_test.dart`.

That test is the only one that exercises the client against the real server contract, and it
is skipped unless `SYNC_BACKEND_URL` is set, so CI never runs it. The `backend` job already
starts a Postgres through testcontainers. Proposal: a CI job with a `postgres:17` service,
`alembic upgrade head`, uvicorn in the background with a raised group rate limit, then
`SYNC_BACKEND_URL=… flutter test test/sync/sync_two_devices_test.dart` — the recipe in
`.llmwiki/Testing.md`, *Group sync against a local backend*.

## Group management: no device list, no way to remove a lost phone

**Status:** done (2026-09-14) — closed by `feat/group-device-list`, for the device half only.
`GET /groups/me/devices` lists the group's active devices (id, label, joined, last seen).
Settings → Group → *Devices* shows them, marks this device, and removes any other one after a
confirmation. That goes through the existing revoke route, which also rotates the invite code,
and the app shows the new code at once. The group settings half stays in `TODO.md` as
*Group settings in the app — for 1.2*. The revoke-another-device prerequisite mentioned
below had already landed on 2026-09-13 (`fix/budget-ws-revocation`). The user reopened the
2026-09-13 scope decision because a lost phone could otherwise only be shut out by rotating
the invite code.

The server has endpoints the app does not use: `GET/PATCH /groups/me` (comment style,
language, LLM budget), `GET /groups/me/usage`, the group-scoped comments, and revoking
*another* device (`POST /groups/me/devices/{id}/revoke`). The last one has no way to list
devices first, so a lost phone can only be shut out by rotating the invite code and — once
the backend review's MEDIUM *Revocation is reversible* item lands — by revoking it. Proposed,
in order of value: a `GET /groups/me/devices` endpoint (id, label, joined, last seen) and a
device list in Settings → Group with a revoke action; then group settings. Per-field LWW
(`field_versions`, see `.llmwiki/Sync.md`) belongs to the same "v2 of groups" conversation.

## Backend review: no rate limit on authenticated writes; the raw payload is persisted and replayed

**Status:** done (2026-09-13) — closed by `fix/p1-hardening-quick`. `/sync/push` is limited
per device (`SYNC_PUSH_RL_PER_MINUTE` / `_PER_HOUR`, 60 / 1200, the in-memory limiter under
its own `sync_push` bucket — the `rate_limits` table has one row per device and is the LLM
quota), and `list_comments` takes `limit` 1–100, 422 outside.

> **Partly done** (2026-09-13, `fix/sync-contract`) — `change_log.payload` now holds only the
> payload's known client columns (`_logged_payload` in `sync.py`), never unknown keys nor
> `id`/`group_id`/timestamps. The per-device limiter on `/sync/push` and the `list_comments`
> bound are still open.

`/sync/push` stores `delta.payload` verbatim in `change_log` (`sync.py:291`), unknown keys
included, up to 256 KiB per request and 500 deltas, and `/sync/pull` serves it back to every
member. A member can bloat the NAS disk and every sibling device. Proposed: persist only the
coerced, known columns; a per-device limiter on `/sync/push` (reuse `check_and_increment`
with a scope of its own). Also `list_comments` (`backend/app/routes/comments.py:349`) takes
`limit: int = 10` unbounded — a negative value is a Postgres error and a 500:
`Query(ge=1, le=100)`.

## `_snack` hardcodes `Colors.green` / `Colors.red`

**Status:** done (2026-09-13) — closed by `fix/p1-hardening-quick`. `_snack` now takes
`colorScheme.primary` / `onPrimary` for a confirmation and `colorScheme.error` / `onError` for a
failure, so all six call sites follow the theme.

Noted 2026-09-11, while fixing the section-header colours in the same file.

`lib/screens/settings_screen.dart:28-33` picks its snackbar background from
`ok ? Colors.green : Colors.red` — the same theme-blindness just fixed four lines below, in the
section headers. Saturated red and green sit badly on the dark theme's surfaces and ignore the
scheme entirely.

The analysis screen's new failure snackbar uses `Theme.of(context).colorScheme.error`, so the
two now disagree about what a failure looks like. The fix is `colorScheme.error` /
`onError` for the failure case and `colorScheme.primary` (or a tertiary) for the success one,
across the six `_snack` call sites. Not folded into the header fix because it changes the look
of every settings confirmation, not just a label colour.

## The server's player-name rule refuses names with combining marks

**Status:** done (2026-09-13) — closed by `fix/player-name-combining-marks`. The rule is now
`^(?:\p{L}\p{M}*|\p{N}|[ \-'.])+$` on both sides: a combining mark is accepted right after a
letter (or a mark accepted before it) and refused anywhere else. `sanitize_player_name`, which
filters names for the ZapZap prompt, follows the same walk, so "रवि" no longer reaches the
prompt as "रव". Tests per script in `backend/tests/test_sync.py` and
`test/sync/sync_ids_test.dart`.

Noted 2026-09-13, while mirroring the rule on the client.

`is_valid_player_name` (`backend/app/models/player.py`) accepts a character when
`str.isalpha()` or `str.isdigit()` is true. Combining marks — Devanagari vowel signs such as
the `ि` in "रवि", Arabic harakat, some Vietnamese forms written with combining accents — are
categories Mn/Mc, for which `isalpha()` is false. A Hindi user's player "रवि" therefore
cannot be shared with a group, although Hindi is one of the app's ten languages. The client
mirrors the rule (`lib/services/sync/sync_ids.dart`, `isSyncablePlayerName`) so the user is
told before sharing rather than meeting a rejected delta. Proposal: accept `Mn`/`Mc` after a
letter (`unicodedata.category`), keep refusing everything the rule exists for (`<`, `>`,
braces, control characters), and change both sides in one PR with a test per script.

## Backend review: any member may raise the group's LLM budget to 10 000 ¢ a month

**Status:** done (2026-09-13) — closed by `fix/budget-ws-revocation`. `MAX_BUDGET_CENTS`
(`app/config.py`, unset = `DEFAULT_BUDGET_CENTS`, and an empty value from compose counts as
unset) is enforced in `update_settings` with a 422. Listed in `.env.example`,
`docker-compose.prod.yml` and `.llmwiki/Deployment.md`. Tests in `backend/tests/test_groups.py`.
A group already above the ceiling keeps its budget until someone changes it. Noted
2026-09-13 in the *Backend security review*.

`backend/app/schemas/groups.py:60` lets `PATCH /groups/me/settings` set
`monthly_budget_cents` up to 10 000; the operator only controls the *initial* value through
`DEFAULT_BUDGET_CENTS`. Proposed: a `MAX_BUDGET_CENTS` setting — an operator-owned ceiling,
defaulting to `DEFAULT_BUDGET_CENTS` — enforced in the route, and listed in
`.env.example` and `.llmwiki/Deployment.md`.

## Backend review: one Postgres connection per WebSocket, no per-device cap

**Status:** done (2026-09-13) — closed by `fix/budget-ws-revocation`. `app/services/notify.py`
holds one LISTEN connection for the process and fans notifications out to a queue per
stream; a lost connection closes every stream with 1012 so clients reconnect and pull.
`/sync/stream` refuses a device's fourth concurrent stream with 1013 before `accept()`
(`MAX_STREAMS_PER_DEVICE`). Tests: `backend/tests/test_sync_stream_cap.py` and, on real
Postgres, `test_streams_share_one_listen_connection` (three streams, one `countscore-listen`
row in `pg_stat_activity`). `POST /sync/ws-ticket` still has no rate limit of its own —
tickets cost a dict entry for 60 s, and the stream cap bounds what they can open. Noted
2026-09-13 in the *Backend security review*.

`backend/app/services/notify.py:49` opens a dedicated `asyncpg.connect` for every
`/sync/stream`, and `POST /sync/ws-ticket` has no rate limit. One authenticated device can
open hundreds of streams and exhaust Postgres `max_connections` (default 100, of which the
app's own pool wants 30) — a service-wide outage from inside one household. Proposed: a
single shared LISTEN connection with an in-process fan-out (`dict[group_id, set[Queue]]`),
and a cap of about three concurrent streams per device.

## Backend review: revocation is reversible by the revoked party

**Status:** done (2026-09-13) — closed by `fix/budget-ws-revocation`. Revoking *another* device
now rotates `share_token` and returns it (200, `GroupWithShareToken`), like
`rotate-share-token`. Revoking the caller's own device stays a 204 without rotation: that is
how the app leaves a group (`GroupProvider.leave`), and rotating there would stale everyone
else's invite link for nothing — the plan's first idea, a 400 on self-revoke, would have
broken leaving. Tests in `backend/tests/test_groups.py`. Noted 2026-09-13 in the *Backend
security review*.

`POST /groups/join` returns `share_token` to the joiner (`backend/app/routes/groups.py:132`),
so every device holds it for good. Revoking a device (`groups.py:171`) without rotating the
token lets the revoked device re-join at once and get a fresh token. Proposed: rotate
`share_token` inside `revoke_device` and return the new one, as `rotate-share-token` does —
or, at minimum, document in `.llmwiki/Api.md` that a revoke is meaningless without a rotate.
Belongs with the owner-role debt already listed in `.llmwiki/Security.md`.

## Backend review: every per-IP rate limit is bypassed by a client-supplied `X-Forwarded-For`

**Status:** done (2026-09-13) — closed by `fix/ip-spoofing-zapzap-payload`. `client_ip()` now
returns `request.client.host` and nothing else; `docker-compose.prod.yml` pins the network
to `172.28.87.0/24` and sets `FORWARDED_ALLOW_IPS=172.28.87.1`, so uvicorn keeps the hop
Web Station appended. The PoC is inverted in `backend/tests/test_ip_rate_limit.py` (six
group creations with a rotating header → 201 ×3 then 429, one bucket), plus a test of
uvicorn's resolution under that trusted list. The wiki blocks that pointed here are gone.
Noted 2026-09-13 in the *Backend security review*.

> **Reopened and closed again (2026-09-13)** — the production check after deploying it
> answered `404` four times: Synology Web Station sets `X-Real-IP` and does not set
> `X-Forwarded-For` at all, so uvicorn trusted the client's own header. `fix/trust-x-real-ip`
> replaced `FORWARDED_ALLOW_IPS` with `TRUSTED_PROXY_IPS` and `TrustedProxyMiddleware`, which
> believes `X-Real-IP` from the gateway only, and runs uvicorn with `--no-proxy-headers`. The
> lesson: the fix was tested against how a reverse proxy usually behaves, not against the
> portal config on the NAS — read that file before trusting any proxy header.

> Also covers the `auth_fail` bucket added on 2026-09-13 in `app/auth.py`: until this lands,
> a client rotating the header escapes the cap on failed token checks too. The cost per
> attempt is one argon2 verify against a real device id, no longer a scan.

`backend/app/services/ip_rate_limiter.py:40-45` takes the **first** hop of
`X-Forwarded-For`. A reverse proxy — Web Station's nginx included — *appends* the real
address, so a client sending `X-Forwarded-For: <anything>` arrives as `<anything>, <real>`
and the first hop is attacker-chosen. That header is the **only** guard on the two
unauthenticated paid LLM endpoints (cost abuse), on `POST /groups` (unbounded device
creation, which feeds the next item) and on `POST /groups/join` — `.llmwiki/Api.md` says
this limit "caps `share_token` guessing", which is therefore false. Each spoofed value also
creates a fresh `_buckets` entry that the hourly sweep is the only thing bounding.

PoC: 20 `POST /groups` with a rotating header against a 3-per-minute limit → 20 × 201, and
22 buckets in memory.

Why it "works" today: uvicorn's `ProxyHeadersMiddleware` (0.52.4) trusts `127.0.0.1` only,
and inside the container the peer is the Docker bridge gateway, so `request.client.host` is
the gateway for everyone. The app compensates by parsing the raw header itself, and that
parsing is the flaw.

Proposed fix:
- Delete the header parsing in `client_ip()`; use `request.client.host` and nothing else.
- Let uvicorn resolve the client: `--forwarded-allow-ips=<docker bridge subnet>` (or the
  `FORWARDED_ALLOW_IPS` env var) in `docker-compose.prod.yml` and the Dockerfile `CMD`.
  With a *specific* trusted list uvicorn walks the chain right-to-left and returns the first
  untrusted hop (`uvicorn/middleware/proxy_headers.py`, `get_trusted_client_address`),
  which cannot be spoofed as long as the port stays bound to `127.0.0.1` — it is. Never
  `*`: with `always_trust` uvicorn takes the leftmost hop again.
- `backend/tests/test_ip_rate_limit.py` currently *relies* on the spoof to simulate distinct
  clients; rewrite it to set the ASGI `client` address instead.
- Wiki: the `Status: Outdated` blocks in `.llmwiki/Security.md` and `.llmwiki/Api.md` point
  here; remove them when this lands.

## Backend review: `POST /comments/zapzap-analysis` takes an unvalidated `dict`

**Status:** done (2026-09-13) — closed by `fix/ip-spoofing-zapzap-payload`. `ZapZapPayload`
(`backend/app/schemas/comments.py`) returns 422 on a wrong shape or a count out of bounds
(1–12 players, ≤ 200 rounds, ≤ 12 scores a round, ≤ 10 history entries a player) and
**clips rather than refuses** text — decided with the user, because the app never bounded
game names, round comments or player names locally and installed clients must keep their
analysis. Player names go through `sanitize_player_name` (`app/models/player.py`, the sync
allow-list as a filter); history is re-keyed by the filtered name and entries under any
other name are dropped. The `invalid payload: {e}` detail went with the old `try`. Device
auth and a budget on this endpoint remain the longer-term item in `.llmwiki/LlmProviders.md`.
Noted 2026-09-13 in the *Backend security review*.

`backend/app/routes/comments.py:119` declares `body: dict`. `build_zapzap_user_message`
(`backend/app/services/zapzap_prompt.py:71`) interpolates every field verbatim — player
names, each round's free-text `comment`, every history entry, the game name — with no
length or count limits beyond the 256 KiB body cap, no player-name allow-list (the sync
path has `is_valid_player_name`; this path does not), and none of the five injection layers
`.llmwiki/LlmProviders.md` documents for the Claude path. With `max_tokens = 8192` and the
per-IP limit bypassable, anyone who knows the URL has unlimited generations on the
operator's key, and the free-text fields steer the prompt at will.

Proposed fix: a Pydantic `ZapZapPayload` in `backend/app/schemas/comments.py` — players ≤
12 with names through `is_valid_player_name`, rounds ≤ 200, `comment` ≤ 200 characters,
history ≤ 10 entries per player with bounded fields, game name ≤ 64 — returning 422 on
violation, and the mobile payload (`lib/screens/game_analysis_screen.dart`) checked against
it. Longer term, what `LlmProviders.md` already calls "to harden": device auth and the
`rate_limits` budget on this endpoint.

## The Flutter sync client does not exist

**Status:** done (2026-09-13) — closed by three pull requests to `main`: `fix/sync-contract`
(#19, the server contract and three security findings), `feat/schema-v10` (#20, local schema
v10, tombstones for shared rows, a real v5 → v10 upgrade test) and `feat/group-sync` (the
client: schema v11 capture triggers, `lib/services/sync/`, `GroupProvider`, Settings → Group,
per-game sharing, the privacy documents). Verified by `test/sync/`, by a two-device test
through a real backend, and by two browser contexts driving the PWA against a local server.
The protocol as built is in `.llmwiki/Sync.md`; its deliberate limits in
`.llmwiki/KnownLimits.md`. Noted 2026-09-09, during a branch/commit review.

> **Design settled with the user (2026-09-13).** Sync runs only once a server URL is set
> *and* the device has created or joined a group from Settings (the `share_token` is pasted
> once, `/groups/join` returns the device token, kept in `flutter_secure_storage`). Sharing
> is **per game**, on by default for new games; an existing game can be shared later, never
> unshared. Players and game types are **merged by normalised name** through a local link
> table — local players stay global (`group_id IS NULL`), so point 4 below no longer reopens
> the player queries — and their first server UUID is a uuid5 of group and name, so every
> device computes the same one. `rounds.comment`, `game_analyses` and the game dates sync.
> A delete propagates and wins. Leaving revokes the device and turns shared games back into
> local ones. A round-number conflict renumbers the loser to the next free number and says
> so. WebSocket plus polling, Android and PWA. All of it ships in 1.1.0 with the Drift switch.
>
> **What A changed on the server contract.** Each delta runs in its own savepoint; entities
> and parents are group-scoped; reasons a client branches on are stable codes
> (`round_number_taken`, `score_exists`, `name_taken`, `analysis_exists`, `parent_missing`,
> `not in group`); a delete beats any later upsert; unique rules ignore tombstones; colours
> are `BIGINT`; `rounds.comment` and the `game_analysis` entity exist; the log stores only
> client columns; device tokens are `<device id hex>.<secret>`. See [[Sync]] and [[Api]].
> Points 2 and 3 below are answered by the above; point 1 and the quarantine are C's work.

Milestones 5 to 7 are marked Done in `.llmwiki/Architecture.md`, and on the server they
are: groups, delta-log sync with row-level LWW, and `/sync/stream` over Postgres
LISTEN/NOTIFY are implemented and tested. **Nothing in the app consumes any of it.**

`lib/services/sync_service.dart` is referenced by the documentation but is not on disk.
`lib/services/backend_client.dart` now exists (2026-09-11) but covers only two calls,
`zapzapAnalysis` and `health`; it holds the base URL and is where a sync client would land.
The single feature in `lib/` that makes a network call is still the ZapZap analysis — and
only once the user has configured a backend, since there is no default URL.

So the backend is a working service with no client, and both the mobile app and the PWA are
still purely local. This is the largest gap between what the wiki says the project is and
what it does, and it is the thing that would make group sharing real.

It needs its own design pass, not a quick patch: an outbox on the Drift side, conflict
handling that matches the server's LWW rules — **row-level**, not per field, whatever
`.llmwiki/Sync.md` used to say (`backend/app/routes/sync.py:184-199`) — device-token
storage, and a reconnect policy for the WebSocket. See [[Sync]] and [[Architecture]].

### What the design pass must settle first

Reviewed 2026-09-09 against both sides of the wire. The four items below are not
implementation detail — each one can invalidate code written before it is answered, and
none of them was visible in the sketch above. Together they are most of the work.

**1. Local `int` primary keys against server `UUID` primary keys.** The local schema keys
every table on `integer().autoIncrement()` and carries its foreign keys as *local* ints —
`rounds.gameId`, `scores.playerId`/`roundId`, `games.gameTypeId`, `game_players.gameId`/
`player_id` (`lib/services/drift/tables.dart`). The server keys everything on UUID, foreign
keys included (`backend/app/models/game.py`). So a delta cannot be built by serialising a
local row, and cannot be applied by writing a pulled payload: it needs a bidirectional
id↔uuid resolution layer over six entity types, in both directions. It also needs an answer
for **deltas that arrive before their parent** — a `score` whose `round` is not local yet —
which means a quarantine queue and a replay, not a straight apply loop. This is the largest
single piece and it was missing from the estimate; `.llmwiki/Sync.md` still says "roughly
500 LOC of client".

**2. Local fields that have no server column would vanish silently.** `_coerce_payload`
drops every key that is not a mapped column (`backend/app/routes/sync.py:77`, `if key not in
columns: continue`) — no error, no rejected status. Today that means:

- `rounds.comment` exists locally and **not** in the server `Round` model. Round comments
  would not survive a round trip.
- `game_analyses` is not in `_ENTITY_MAP` at all (the six types are `player`, `game_type`,
  `game`, `game_player`, `round`, `score`), so ZapZap analyses never sync.
- `game_players` carries `name` and `uuid` locally; the server row has a composite PK, no
  `uuid` and no `deleted_at`, so its delete is a hard delete with no tombstone.
- `games` keeps `createdAt`/`lastModified` as ISO text locally against `started_at`/
  `ended_at` on the server — a modelling difference, not a mapping.

Decide per field: add the column server-side, or accept it as device-local and say so. A
"shared game" that is silently only partly shared is worse than one that refuses to share.

**3. Merging pre-existing local data at join time is undefined, and the common case
fails.** The server holds `uq_players_group_name` on `(group_id, name_normalized)`
(`backend/app/models/player.py:44`). Two phones that each already have a local "Alice" —
different UUIDs, same name — join the same group; the second push hits `IntegrityError` and
comes back `rejected` with "integrity constraint violation". Reading the status is not the
hard part: the question is what the app does next. Adopting the server's UUID rewrites the
player's identity, and **player stats have been keyed by player UUID since v9**
([[SchemaV10]]), so that reindexes the whole statistics history. Options worth costing —
dedupe by normalised name at join, keep a local↔server player mapping table, or (cheapest)
do not sync the global player catalogue at all in v1 and create group players fresh, which
sidesteps the constraint and leaves stats identity untouched.

**4. The repositories are group-blind by construction.** `group_id IS NULL` is hardcoded in
about a dozen player queries in `lib/repositories/drift/drift_repositories.dart` (lines 288,
320, 397, 406, 420, 425, 449, 478, 482, 511, 646). A player with a non-NULL `group_id` is
invisible to the player list, the picker and the stats. So this is not an additive feature:
it reopens the repository layer that was just ported to Drift and **has not shipped yet**
(production still runs sqflite v9 — see [[DataLayer]]). Sequencing matters; shipping the
engine swap and the first network write path in one release doubles the blast radius on a
project with no backend alerting (CI exists since 2026-09-09).

Two cheap prerequisites fall out of the above and can be done independently:

- ~~Extract a `BackendClient` from `lib/screens/game_analysis_screen.dart`.~~ Done
  (2026-09-11): `lib/services/backend_client.dart`; the screen only injects an `http.Client`
  for tests.
- ~~Land CI before the client, not after.~~ Done (2026-09-09): `.github/workflows/ci.yml`,
  see `DONE.md`.

## Backend security review — HIGH: cross-group data tampering through `POST /sync/push`

**Status:** done (2026-09-13) — closed by `fix/sync-contract`, the backend half of the sync client work. `_apply_delta` loads the entity and refuses it (`not in group`) unless it belongs to the caller's group — directly for players, game types and games, through the game for rounds and analyses, through round and game for scores; every parent a payload names must be in the group or the delta is `rejected` with `parent_missing`; the LWW lookup is scoped by `group_id`. The PoC is inverted in `backend/tests/test_sync_contract.py` (`test_a_device_cannot_touch_another_groups_game`, `test_child_entities_are_scoped_through_their_parents`). Noted 2026-09-13 in the backend security review (`TODO.md`, *Backend security review — 2026-09-13*).

Broken object-level authorisation. `backend/app/routes/sync.py:152` looks an entity up **by
UUID only**, with no group filter. For `player`, `game_type` and `game` an existing row from
*another* group is then overwritten (`sync.py:204-209`) and its `group_id` is **reassigned to
the caller's group** — the comment at `sync.py:144` ("clients cannot move entities across
groups") states the opposite of what the code does. `delete` (`sync.py:156`) tombstones any
UUID. `round` and `score` carry no `group_id` at all, and their `game_id` / `round_id` /
`player_id` payload keys go through `_coerce_payload` unchecked, so a round can be attached
to any group's game. Only `game_player` verifies ownership (`_apply_game_player`).

PoC: a device in group B, knowing only the UUID of a game in group A, pushed four deltas —
rename it, which also moved it to B; attach a round to it; tombstone it. All answered
`applied`; the row ended up named by B, owned by B, deleted, with B's round on it.

The realistic attacker is a **revoked device**: it holds every UUID of its former group,
creating a new group is free and unauthenticated, so revocation does not protect the
group's data at all. This is a prerequisite for the sync client above, not a follow-up to it.

Proposed fix:
- Scope the lookup at `sync.py:152` with `col(cls.group_id) == auth.group.id` for the three
  group-bearing entities. A UUID that exists in another group must come back `rejected`,
  never adopted: with the lookup scoped, the create path hits the primary key and the
  existing `IntegrityError` branch already maps that to "integrity constraint violation".
- Parent checks for the two child entities, mirroring `_apply_game_player`: `round.game_id`
  must name a `Game` in the group; `score.round_id` a `Round` whose game is in the group and
  `score.player_id` a `Player` in the group; `game.game_type_id`, when present, a `GameType`
  in the group. Reject otherwise.
- Scope the LWW lookup on `change_log` (`sync.py:191`) by `group_id` as well.
- Regression tests in `backend/tests/test_sync.py` — the PoC inverted — and fix the comment.


## Backend security review — HIGH: the O(N) argon2 scan is an unauthenticated CPU denial of service

**Status:** done (2026-09-13) — closed by `fix/sync-contract`, the backend half of the sync client work. Tokens are now `<device id hex>.<secret>`: `require_device` fetches one row and runs at most one argon2 verify; a malformed token or an unknown device is refused without hashing; failed checks count in a per-IP `auth_fail` bucket (`AUTH_FAIL_RL_PER_MINUTE` 10 / `AUTH_FAIL_RL_PER_HOUR` 60) that answers 429 before any hashing. Alembic `0002_sync_contract` revokes every device holding an old opaque token. That bucket keys on `client_ip()` and so inherits the open `X-Forwarded-For` finding until it is fixed. Tests: `backend/tests/test_auth.py`. Noted 2026-09-13 in the backend security review (`TODO.md`, *Backend security review — 2026-09-13*).

`backend/app/auth.py:74-77` runs one argon2 verify — 30 ms measured on the dev machine —
per non-revoked device row for **any** bearer token, valid or not, before answering 401, and
nothing rate-limits that path. Measured: 20 devices → 609 ms per bogus request; 1 000
devices → about 30 s. The item above lets an attacker create devices without bound, so the
chain is: spam `POST /groups`, then a trickle of requests with a junk token keeps the single
worker saturated. `.llmwiki/KnownLimits.md` lists this as a scaling limit at ~1 000 devices;
it is also an attack at any size. The WebSocket handshake stopped paying this on 2026-09-09;
the HTTP path never did.

Proposed fix: no shipped client exists, so the token format is free to change. Issue tokens
as `<device_id hex>.<secret>`: `require_device` parses the id, fetches **one** row, does
**one** verify. The alternative that keeps the opaque format is a `token_lookup` column
holding the SHA-256 of the raw token, indexed, then one argon2 verify on the candidate row
— an Alembic revision, via the `db-migration` skill. Either way, add a per-IP bucket on
401s as defence in depth, and update `KnownLimits.md` and `Security.md`.


## Backend security review — not security: `server_seq` can collide under concurrent pushes

**Status:** done (2026-09-13) — closed by `fix/sync-contract`, the backend half of the sync client work. `push` reads the group row `FOR UPDATE` and hands out sequence numbers from the new `groups.last_server_seq`; `ix_change_log_group_seq` is unique; each delta runs in its own savepoint, so an `IntegrityError` rejects that delta alone instead of rolling back the batch. Tested on Postgres in `backend/tests/test_sync_ws_integration.py` (`test_concurrent_pushes_to_one_group_get_distinct_server_seqs`). Noted 2026-09-13 in the backend security review (`TODO.md`, *Backend security review — 2026-09-13*).

`_next_server_seq` (`backend/app/routes/sync.py:115`) is `max + 1` inside the transaction
with no lock, and `ix_change_log_group_seq` is not unique, so two pushes in the same group
at the same moment can share a `server_seq` — and a puller paging with `> since_seq` can
skip one of them. Same class as the dedup index: a concurrent retry of one delta hits the
unique `(origin_device_id, client_lamport)` index and comes back as a 500 instead of
`duplicate`. Fix: `SELECT … FOR UPDATE` on the group row (or a per-group sequence) and a
unique index on `(group_id, server_seq)`; catch the dedup `IntegrityError`.


## The Flutter web app has no deployment path

**Status:** done (2026-09-13) — closed by `chore/pwa-deploy`: the backend container serves the PWA under `PWA_BASE_PATH` on its own host (no Web Station change, same origin as the API), and `scripts/deploy_web.sh` builds for that sub-path, reading it from the NAS `.env`, then publishes over ssh with a rename swap and a one-step rollback. The target stays in the untracked `backend/scripts/deploy.env`. Procedure in the `web-deploy` skill, facts in `.llmwiki/Deployment.md`. Noted 2026-09-09 during the LLM-wiki migration.

`.llmwiki/Deployment.md` covers the FastAPI container completely. For the PWA there is
nothing: no vhost, no Web Station config, no deploy script, no documented `--base-href`.
The app is built and served by hand. Whoever deploys it next has to rediscover how.
See `.llmwiki/Web.md`.

## `web/CLAUDE.md` is published with the PWA

**Status:** done (2026-09-13) — closed by `chore/pwa-deploy`: moved to `.claude/rules/web.md`, a path-scoped rule outside the tree Flutter copies. `build/web` no longer contains it, and `scripts/deploy_web.sh` refuses to publish a build holding any `.md` file.

Flutter copies everything under `web/` into the build output, so `build/web/CLAUDE.md`
ships to whoever serves the PWA — internal instructions on a public URL. Harmless today,
but it should either move out of `web/` or be stripped by whatever deploy step the PWA
eventually gets (see "The Flutter web app has no deployment path" below).

## Refresh the committed `web/drift_worker.js`

**Status:** done (2026-09-13) — closed by `chore/pwa-deploy`: `web/drift_worker.js` copied byte-for-byte from the drift 2.34.4 package root, then validated by the web e2e (all tests passed, headless Chrome 153) and by a manual launch of a `--base-href=/countscore/` release build, a game created and still there after a reload.

`web/drift_worker.js` is 351,222 B; the worker drift 2.34.4 ships at its package root
(`~/.pub-cache/hosted/pub.dev/drift-2.34.4/drift_worker.js`) is 355,222 B. The committed
copy is an older build than the drift runtime the app is compiled against. The PWA works
today, but a worker/runtime mismatch is exactly the class of bug that shows up as an
inexplicable web-only failure.

Copying the package's file over ours is a one-line change — but it must be followed by a
real PWA launch and the web e2e run, not just a green build, because
`connection_web.dart` failures surface only at runtime. That is why it was not folded into
the SDK upgrade. See `.llmwiki/Web.md`.

Note this also settles the old question of whether to untrack the two binaries: they stay
tracked **by choice** (a fresh clone should not have to fetch binaries to run the PWA), not
because the repo is their only source. It never was.

## `ruff format` has never been run on `backend/`

**Status:** done (2026-09-13) — run on `fix/backend-todo` in its own `chore:` commit: 47 files reformatted, 86 tests green, `ZAPZAP_SYSTEM_PROMPT` checked identical before and after. The hook that refused the command was removed at the user's request; `ruff format --check .` is now a commit gate and a CI step instead.

It would rewrite 43 of 50 files. Left out of the 2026-09-09 backend pass on purpose, so
the functional diff stayed readable. It wants its own `chore:` commit.

## `GEMINI_MODEL` defaults to a model that is quota-0 on the free tier

**Status:** done (2026-09-13) — closed by `fix/backend-todo` (`3f04b3a`). Both tracked defaults, `.env.example` and `backend/README.md` now say `gemini-2.5-flash`, with a `/health` test on the default. The "production sets the bad value explicitly" finding below was wrong: the NAS `.env` had no `GEMINI_MODEL`; the value seen in the container was the compose default. Production now sets `GEMINI_MODEL=gemini-2.5-flash` explicitly anyway.

`gemini_model: str = "gemini-2.5-pro"` (`backend/app/config.py:32`), duplicated as
`${GEMINI_MODEL:-gemini-2.5-pro}` in `docker-compose.prod.yml:40`. On a free-tier Google key
`gemini-2.5-pro` has a quota of **0**, so switching `LLM_PROVIDER=gemini` without also setting
`GEMINI_MODEL` fails immediately — exactly the class of trap just closed for Mistral, on the
provider next door. `gemini-2.5-flash` works without billing enabled.

**Worse than a bad default: production sets the bad value explicitly.** Checked inside the
container on 2026-09-11 — the NAS `.env` carries `GEMINI_MODEL=gemini-2.5-pro` alongside a
valid `GEMINI_API_KEY`. So the ready-made escape hatch from the Mistral rate limit
(see below) is armed to fail: flipping `LLM_PROVIDER=gemini` alone would swap a 429 for a
quota-0 error. Whoever switches must set `gemini-2.5-flash` in the same edit.

Not fixed inline because nothing currently runs on gemini, and because picking the default is
the same product decision the Mistral one was. When it is fixed, remember the default lives in
**two** tracked places, the compose one wins in production — and that the NAS `.env` overrides
both, so fixing the repository alone would not fix this deployment.

## Backend tests read the developer's local `backend/.env`

**Status:** done (2026-09-13) — closed by `847812f`. `tests/conftest.py` sets `Settings.model_config["env_file"] = None` before `app.db` builds its settings; `test_settings_ignore_a_local_env_file` writes a `.env` with `gemini-2.5-pro` into the working directory and fails without the override.

`Settings` has `env_file=".env"` (`backend/app/config.py:11`) and pytest runs from `backend/`,
so every test that touches `get_settings()` picks up the untracked local `.env`. A machine with
`BEDROCK_MODEL_ID=us.meta.llama3-1-70b-instruct-v1:0` in it makes an assertion on the code
default fail, while CI — which has no `.env` — passes. The tests are therefore not reproducible
across machines.

`conftest.py:19-20` already neutralises `ANTHROPIC_API_KEY` and `DATABASE_URL` with
`os.environ.setdefault`, which does not help: the `.env` file is read regardless. The fix is to
point `Settings.model_config["env_file"]` at nothing during tests, or to have `conftest.py`
construct settings with `_env_file=None`. Worked around for now by setting every value the new
tests assert (`tests/test_health.py`), which is correct but does not protect the next test.

## The dev `docker-compose.yml` cannot serve the ZapZap endpoint

**Status:** done (2026-09-13) — closed by `090ff38`. The `api` service uses `env_file: .env` and overrides only `DATABASE_URL`; checked with `docker compose config` against a throwaway `.env`.

`backend/docker-compose.yml:22-35` passes six variables into the `api` container —
`DATABASE_URL`, `ANTHROPIC_API_KEY`, `COMMENT_MODEL`, `DEFAULT_BUDGET_CENTS`, `CORS_ORIGINS`,
`LOG_LEVEL` — and **none** of `LLM_PROVIDER`, `AWS_*`, `BEDROCK_MODEL_ID`, `GEMINI_*` or
`MISTRAL_*`. So `POST /comments/zapzap-analysis` on a local `docker compose up` always answers
503 "LLM provider not configured", whatever `backend/.env` holds.

`docker-compose.prod.yml` does not have the problem: the NAS `.env` is mounted as a file, so
the whole environment reaches the container.

The workaround used on 2026-09-11 was `.venv/bin/uvicorn app.main:app --port 8000`, which
loads `.env` through pydantic-settings and needs no Postgres — the endpoint is stateless
(`app/routes/comments.py:114-132`, no `session` parameter) and `Settings.database_url` has a
default. That works, but it means the documented local stack cannot exercise the one feature
the app actually calls.

Fix: add the provider variables to the `api` service's `environment:` block, or switch it to
`env_file: .env` like production. The second is smaller and cannot drift again.

## The NAS hostname is still in git history

**Status:** done (2026-09-13) — closed by decision, not by code: option 1, exposure accepted. A hostname and an RFC 1918 address, no credential. Recorded in `.llmwiki/Deployment.md`.

`feat/configurable-backend-url` removed `countscore.ombivince.synology.me` and the LAN
registry address `192.168.1.25:5050` from the working tree: they now live in the untracked
`backend/scripts/deploy.env`. **Every commit before that one still contains them**, and the
repository is public, so `git log -p` and the GitHub UI still show them.

Nothing was rewritten on purpose: `CLAUDE.md` forbids force-pushing and rewriting commits
already on `origin/main`, and a rewrite would break every existing clone and every link to a
commit. The exposure is a hostname and an RFC 1918 address, not a credential — the values are
not secret, they are simply personal infrastructure that no longer belongs in a public tree.

If that is judged worth closing, the options, worst to best:

1. Leave it. The host is behind TLS with its own auth surface; knowing the name buys an
   attacker a target list entry and nothing else.
2. Rename the Synology DDNS host, making the old name dead. Cheap, and it invalidates the
   history without touching git. Requires re-issuing the Let's Encrypt certificate and
   updating `deploy.env` — the app no longer needs updating, which is the point of this
   change.
3. `git filter-repo` over the history plus a force-push. Correct in principle, forbidden by
   `CLAUDE.md`, and it rewrites every sha in the project.

Option 2 is the one worth doing if it is done at all.

## The Mistral account is rate-limited, so the analysis still 502s

**Status:** done (2026-09-13) — closed by switching production to Gemini. NAS `.env`: `LLM_PROVIDER=gemini`, `GEMINI_MODEL=gemini-2.5-flash` (backup `.env.bak-2026-09-13` beside it); image `e6e1e74` deployed. `/health` reports `gemini` / `gemini-2.5-flash` / `credentials: true`, and a real `POST` with `scripts/sample_payload.json` returned 200 in 13 s with a complete 3,543-character analysis. The "bare HTTP 502" point is closed too (`939ae0d`): a provider quota or throttle now answers 503 + `Retry-After`, and the app shows `analysisErrorUnavailable`. The Mistral account itself was not re-checked.

`POST /comments/zapzap-analysis` in production returns 502 with:

```
RuntimeError: mistral API call failed: RateLimitError: Error code: 429 -
{'message': 'Rate limit exceeded', 'type': 'rate_limited', 'code': '1300'}
```

**Not a throttle we can wait out between calls.** Two attempts 75 s apart both failed, and a
minimal 5-token request to `mistral-small-latest`, issued from inside the container, returns
the same 429. The limit is account-wide — independent of the model and of our payload size —
so it is an exhausted free-tier quota or an account-level cap, not something the code can
retry around.

The configuration is provably correct: `/health` reports
`{"provider":"mistral","model":"mistral-medium-latest","credentials":true}`, and the models
listing confirms the account may use that model. Nothing in this repository is wrong.

**Decision (2026-09-11): wait.** If this is a monthly cap it resets on the billing cycle.
Re-check with a real `POST`; `/health` will keep saying the configuration is fine, because it
is — that is the one thing this endpoint deliberately cannot tell you.

The two other ways out, if waiting does not resolve it:

1. **Add billing to the Mistral account**, lifting the free-tier quota.
2. **Switch to Gemini.** This needs **no code** — `LLM_PROVIDER` is already pluggable
   (`app/services/llm/factory.py`), `docker-compose.prod.yml` already passes `GEMINI_API_KEY`
   and `GEMINI_MODEL`, and production **already holds a Gemini key**. It is two variables in
   `$NAS_DEPLOY_DIR/.env` plus `docker compose up -d` — §2 of the `backend-deploy` skill.

   **But it would fail as currently configured.** Production explicitly sets
   `GEMINI_MODEL=gemini-2.5-pro`, which is quota-0 on the free tier, so the switch must set
   `gemini-2.5-flash` in the same edit. See the entry above.

   Switching also changes the tone of every analysis and sends the payload to a different
   third party, so it implicates [[Security]] and the privacy documents if the recipient
   changes.

Worth doing regardless of which is chosen: **the client shows the user a bare HTTP 502 for
what is really "the server's LLM quota is exhausted"**. The server deliberately returns only
`type(e).__name__` to avoid leaking provider detail ([[Api]]), which is right, but a 429 from
upstream could reasonably map to a distinct status the app can word better than "HTTP 502".

## The ZapZap system prompt hard-codes eight real people's names

**Status:** done (2026-09-13) — closed by `1a1c4e5`: the section and the "favourite player" line were dropped, not moved to per-group config. A parametrised test asserts none of the eight names is in `ZAPZAP_SYSTEM_PROMPT`. No privacy document described the prompt's content, so none changed; `.llmwiki/Security.md` moved it from open debt to history. Deployed with `e6e1e74`.

`backend/app/services/zapzap_prompt.py:52-59` writes eight first names — Thibaut, Vincent,
Lionel, Laurent, Guillaume, Simon, Nadia, Ben — and a one-line reputation for each directly
into `ZAPZAP_SYSTEM_PROMPT`. The prompt is constant, so **those names and characterisations
are sent to the third-party LLM provider on every single request**, whoever is actually
playing, and they reach a provider whose retention we do not control ([[Security]]).

Two separate problems. The privacy one: none of the compliance documents mentions it,
because all three describe what leaves the *device*, and this text never was on the device.
A stranger who installs the app and generates one analysis transmits eight real people's
names without any of it being disclosed. The quality one: the model is being told about
players who are not in the game, which is a strange thing to ask it to write around.

The fix is to move the personalities out of the constant prompt and into per-group
configuration, or to drop them. Either way it is a change to what the provider receives, so
`.llmwiki/Security.md` and the three privacy documents are implicated — see the outbound
data flow rule in `CLAUDE.md`. Not fixed inline because it changes the tone of every
generated analysis, which is a product decision, and the personalities are presumably there
on purpose.

## The sync conflict branch has no test

**Status:** done (2026-09-13) — closed by `e6e1e74`: three two-device tests in `test_sync.py` (older lamport loses whole row including a loser-only field; newer lamport wins; equal lamport broken by `origin_device_id`), each checked by mutating `sync.py`.

`merged_lww` appears nowhere under `backend/tests/`. `test_sync.py` covers push/pull,
idempotence, the round-uniqueness rejection and the payload bounds, but never drives two
devices writing the same entity, so the branch that decides who wins
(`backend/app/routes/sync.py:184-199`) has never run in a test. `.llmwiki/Testing.md`
asserted it was covered until this was checked; the page is corrected.

Cheap to close and worth closing before any client exists, because the client's outbox is
written against whatever this branch actually does: push the same `entity_uuid` from two
device tokens with competing `(client_lamport, origin_device_id)` pairs, assert the loser
comes back `merged_lww` and that the stored row is the winner's — including that a field
only the loser touched is **not** merged in. That last assertion is the one that pins the
row-level behaviour down, and it is exactly the fact the wiki got wrong. See [[Sync]].

## The ZapZap analysis is down in production: Mistral rejects the configured model

**Status:** done (2026-09-11) — closed by `fix/zapzap-mistral-and-analysis-ui`, deployed to
production as `eb9ba02` the same day. **The feature is still down**, but for a different
cause, filed separately in `TODO.md` — see the note at the end.

`POST /comments/zapzap-analysis` returned **502 to every client from 2026-09-09**. Production
ran `LLM_PROVIDER=mistral` without `MISTRAL_MODEL` and inherited the code default
`mistral-large-latest`, which the account's tier rejects:

```
RuntimeError: mistral API call failed: PermissionDeniedError: Error code: 403 -
{'message': 'This model is not available in your subscription tier',
 'type': 'tier_not_allowed', 'code': '1910'}
```

### What the entry got wrong

It recorded the fix as "**one line of production environment**". That was wrong in a way that
mattered: the default lives in **five** tracked places, and
`docker-compose.prod.yml` interpolates `${MISTRAL_MODEL:-…}`, so **the compose default is what
production actually reads**. A default changed in `app/config.py` alone would never have
reached the container. All five now say `mistral-medium-latest`, and the deploy fixed
production without the NAS `.env` being touched at all — which is the proof that the compose
copy was the operative one.

### Verified after deployment

- `GET /health` returns `{"llm":{"provider":"mistral","model":"mistral-medium-latest",
  "credentials":true}}` — the enrichment added by the same change, and the check that would
  have caught the original outage in one free request.
- `GET https://api.mistral.ai/v1/models` with the production key, run from inside the
  container: 46 models, `mistral-medium-latest` **present**, `mistral-large-latest` still
  **absent**. The 403 cause is gone and the replacement is genuinely allowed.
- The 2026-09-09 observation that "the failure is invisible until someone taps the button" is
  closed by `/health`; the alerting half is not, and stays open under [[KnownLimits]].

### It is still down, for a new reason

A real `POST` now fails with **429 `rate_limited`** rather than 403. A 5-token request to
`mistral-small-latest` gets the same 429, so the limit is account-wide, not about the model or
the payload. That is a Mistral account problem, not a code or deployment one, and it is filed
as its own `TODO.md` entry.

---

## A failed regeneration hides the cached analysis until you leave the screen

**Status:** done (2026-09-11) — closed on `fix/zapzap-mistral-and-analysis-ui`.

`_buildBody` in `lib/screens/game_analysis_screen.dart` tests `_error != null` **before**
`_analysisText == null`, so a failed regenerate replaces the existing analysis with the error
state. The stored row is untouched — `upsert` only runs on success, and navigating away and
back shows the text again — but from the user's side their analysis appears to have been
destroyed by a failed refresh.

Two changes worth making together:

1. Keep the cached text on screen and report the failure as a snackbar, or render the error
   above the content rather than instead of it.
2. Stop printing the raw exception. The error line currently reads
   `Échec de la génération de l'analyse` followed by
   `Exception: HTTP 502: {"detail":"upstream LLM error: RuntimeError"}`. Now that the server
   is one the user runs, a status code is genuinely useful to them — but the JSON body and the
   Dart exception prefix are not.

Closed by splitting the failure from the content. `_reportFailure` now writes `_error` only
when there is nothing on screen; with a cached analysis present the failure is a snackbar in
`colorScheme.error` and the text stays put. The `_buildBody` cascade was deliberately **not**
reordered — `_error` is now unreachable while content exists, and moving the branch would have
left a second route back to the same bug. The raw exception is gone too: `BackendClient` throws
`BackendException(statusCode, body)`, the screen shows `analysisErrorStatus` (the status alone)
and sends the body to `debugPrint`. Fixing the throw path also fixed a latent mojibake bug —
`response.body` decodes latin-1 with no charset, where the success path already used
`utf8.decode(bodyBytes)`. Four tests in `test/services/backend_client_test.dart` and two in
`test/screens/game_analysis_screen_test.dart` pin all of it, the second asserting the cached
text survives and that no `Exception:` or JSON body reaches the UI.

---

## The analysis footer sits under the navigation bar

**Status:** done (2026-09-11) — closed on `fix/zapzap-mistral-and-analysis-ui`.

`lib/screens/game_analysis_screen.dart` ends its `SingleChildScrollView` with
`padding: EdgeInsets.fromLTRB(16, 16, 16, 32)` and no `SafeArea`. Scrolled to the bottom, the
"Généré le … · <model>" line is drawn behind the system gesture bar and is partly unreadable.
32 logical pixels is less than the bottom inset on this device.

Fix: wrap the body in a `SafeArea(bottom: true)`, or add
`MediaQuery.viewPaddingOf(context).bottom` to that padding. Pre-existing; the footer has
always been there.

Closed by wrapping the `Scaffold`'s `body` in `SafeArea(top: false)` rather than adding the
inset to one padding: that covers all four branches of `_buildBody`, not just the content one,
and needs no arithmetic. The bottom padding dropped from 32 to a plain `EdgeInsets.all(16)` —
keeping 32 on top of a `SafeArea` would double-count the inset and open a visible gap. The one
precedent in `lib/` is `game_board_screen.dart:342`.

---

## Section headers are hardcoded `Colors.deepPurple`, which is weak in dark mode

**Status:** done (2026-09-11) — closed on `fix/zapzap-mistral-and-analysis-ui`.

Every section header in `lib/screens/settings_screen.dart` ("Apparence", "Serveur", "Écran",
"Sauvegarde") uses `color: Colors.deepPurple` rather than a colour from the scheme. On black
that purple is a low-contrast, saturated blue-violet. The Server section added on 2026-09-11
copied the existing style rather than diverge from its neighbours, so the fix is one change
across all four: `Theme.of(context).colorScheme.primary`.

Closed by taking all four from `Theme.of(context).colorScheme.primary` (the `const` on the
`TextStyle` goes with it). The theme is already seeded on `Colors.deepPurple`
(`lib/main.dart:82,95`), so the hue is unchanged in light mode and correctly lightened in dark.
Every other `Colors.deepPurple` in `lib/` is a card default, an avatar palette entry or the seed
itself, and was left alone. Filed rather than widened: `_snack` in the same file still hardcodes
`Colors.green`/`Colors.red`.

---

## `.llmwiki/Testing.md` is missing a test file

**Status:** done (2026-09-11) — closed on `feat/configurable-backend-url`, which added two
more test files and would otherwise have widened the gap.

Its table listed four files totalling 30 tests while `flutter test` ran 37 across six:
`test/providers/theme_provider_test.dart` (added by `ccc3640`) was never added to the page.
The table now lists all seven files and 50 tests, the suite's current shape.

---

## Release builds declare no `INTERNET` permission, so the analysis cannot work

**Status:** done (2026-09-09) — closed on `fix/release-internet-permission`.

`android/app/src/main/AndroidManifest.xml` declared **no permissions at all**. `INTERNET`
appeared only in `android/app/src/debug/AndroidManifest.xml` and the profile manifest, where
Flutter's template puts it for hot reload. Confirmed against a merged release manifest: it
contained one `uses-permission`, the generated `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`,
and no `INTERNET`.

So **the ZapZap analysis could not work in a signed release build** — the HTTP POST in
`lib/screens/game_analysis_screen.dart` would fail with a `SocketException`. It worked in
debug and profile, which is why it went unnoticed: the e2e device run drives a debug build,
and CI builds a debug APK.

**What closed it.** The permission is now in the main manifest, with a comment saying what
needs it and why the debug manifest does not cover it. Verified the way the bug demanded —
against the *merged* manifest of a real signed build, not the source:

```
$ grep uses-permission build/app/intermediates/merged_manifests/release/*/AndroidManifest.xml
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="com.vemore.countscore.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION" />
```

It shipped with the data safety declaration it depends on, in the same commit, because the
two are only correct together: the permission without the declaration transmits data the
form denies, and the declaration without the permission declares a flow the binary cannot
perform.

The entry left two questions open. Both are answered:

- **Should the release build reach the network at all before the sync client exists?** Yes.
  The ZapZap analysis is a shipped, user-facing 1.1.0 feature and is the only flow the
  permission enables; groups and sync have no client, so they add nothing to the surface.
- **Should the e2e suite run against a release build so this is caught mechanically?** No —
  it calls the production endpoint and needs the keystore, which is why it is already out of
  CI. Instead the `android` CI job now asserts that the main manifest declares `INTERNET`.
  That is a weaker check than a real release build, and deliberately so: it needs no
  keystore, no network and no minutes, and it catches the exact regression that happened.
  What it cannot catch — a permission present in source but lost in the merge — is covered
  by the `release-android` checklist, which now greps the merged manifest every release.

---

## `PUBLISHING.md` predates the backend

**Status:** done (2026-09-09) — closed on `fix/release-internet-permission`.

It described a purely local, offline app. Any release shipping group sharing or LLM
commentary needed the Play Data Safety declaration rewritten first, to disclose the network
calls and what game data leaves the device. **This blocked the next store release.**

`PLAY_STORE_DATA_SAFETY.md` and `privacy_policy.md` had already had that pass on
2026-09-09; `PUBLISHING.md` was the one document still contradicting them, telling the
reader to answer *"Does your app collect or share user data? **No**"* and carrying an
embedded privacy-policy template that said *"No data is transmitted to external servers"*.

**What closed it.** The file was cut from 867 lines to 184 rather than corrected, because
correcting it would have preserved the cause. It had duplicated the keystore and build
procedure from the `release-android` skill and the form answers from
`PLAY_STORE_DATA_SAFETY.md`; the duplicates are what drifted. What remains is
Console-specific only — listing, App Content answers, tracks, rollout, post-launch — with a
table at the top routing everything else to its single source. Stale facts disappeared with
the sections carrying them: Flutter 3.9.2, version 1.0.0+1, the policy template, both "no
data collected" answers, "Shares user data: No", and "verify ProGuard/R8 is enabled".

**Three things the pass turned up that the entry did not predict:**

1. **The actual published listing text was false too.**
   `store_listing/en-US/full_description.txt` and its `fr-FR` twin — the copy that goes on
   the store page, not a template — said *"no data collection"* and *"Your data stays on
   your device"*. That would have put the store listing in direct contradiction with a Data
   Safety form saying "Yes", which is the pairing reviewers look for. Both locales now
   describe the ZapZap analysis as an optional feature and say plainly that data is sent
   when the user asks.
2. **Both listings claimed "Requires Android 5.0 or higher"** against a `minSdk` of 24,
   which is Android 7.0. Corrected in the same pass.
3. **ProGuard/R8 is enabled, and three documents said it was disabled.**
   `android/app/build.gradle.kts:53-54` has `isMinifyEnabled = true` and
   `isShrinkResources = true` — turned on in `1614707` and never reflected anywhere.
   `.llmwiki/Release.md` and the `release-android` skill are corrected; the wiki keeps the
   old claim in a `Status: Outdated` block.

The privacy policy is also published now. `scripts/build_privacy_page.py` renders
`privacy_policy.md` to `docs/privacy-policy.html` with pandoc, GitHub Pages serves it at
`https://vemore.github.io/countscore/privacy-policy.html`, and that URL replaces the
`[YOUR_PRIVACY_POLICY_URL]` placeholder the Data Safety guide carried. Generating rather
than hand-writing the page is deliberate: a hand-maintained copy is exactly how
`PUBLISHING.md` came to contradict the policy in the first place. **Enabling Pages in the
repository settings is still a manual step**, and the release is not submittable until it is
done.

---

## `privacy_policy.md` and `PLAY_STORE_DATA_SAFETY.md` deny a data flow that exists

**Status:** done (2026-09-09) — closed by the rewrite of both documents on
`docs/privacy-disclosure`.

Both compliance documents state that CountScore transmits nothing and uses no third-party
service. That stopped being true when the ZapZap analysis moved server-side: requesting one
posts the game's data — game type, player names, round scores and per-player history — from
`lib/screens/game_analysis_screen.dart` to the backend, which forwards it to an LLM provider
(Bedrock / Gemini / Mistral).

The offending claims:

- `privacy_policy.md:88` — "does not integrate with any third-party services for data
  collection, analytics, or advertising" — and the `:235` summary line "No third-party
  services".
- `PLAY_STORE_DATA_SAFETY.md:15` — "No data is transmitted to external servers, and no
  third-party services are used" — plus `:55` and `:308`.

`README.md` was corrected on 2026-09-09; these two were left alone deliberately, because a
Play Store data safety declaration is a legal statement and rewriting it needs a decision
about what is actually declared (data type, purpose, whether it is "collected" or only
"transmitted", retention at the provider), not a copy-edit.

**This blocks the next store submission that ships the analysis feature.** It is the same
class of problem `.llmwiki/Release.md` already records for `PUBLISHING.md`, which likewise
predates the backend. See [[LlmProviders]] for exactly what the payload contains and
[[Security]] for what the declarations would have to disclose.

**What closed it.** `privacy_policy.md` is now v2.0: it describes the ZapZap payload field by
field, names the recipients (the backend, then AWS Bedrock / Google Gemini / Mistral AI),
states that the backend persists nothing, gives consent as the legal basis, and keeps the v1.0
text identified as the policy for the 1.0.x releases still on the store.
`PLAY_STORE_DATA_SAFETY.md` flips Q1 to "Yes" and declares two data types — Personal info →
Name, and App activity → Other user-generated content — both optional, App functionality, not
linked to identity, not used for tracking.

The posture was a deliberate choice: Google's ephemeral-processing exemption would allow "not
collected", and our own backend meets that bar, but the LLM provider is env-configurable and
free-tier Gemini may train on submitted prompts, so the exemption cannot hold for every
supported configuration. Over-declaring is permitted; under-declaring is what removes apps.

Checking the manifests for this also turned up the missing `INTERNET` permission and the
`WAKE_LOCK` claim that was never true — the first is now its own open item, the second is
corrected in both documents.

---

## `README.md` advertises a Flutter version four majors out of date

**Status:** done (2026-09-09) — closed by the full README refresh on
`docs/privacy-disclosure`.

It claims `Flutter SDK ^3.9.2` in three places (the badge, the Tech Stack section and the
prerequisites). The project runs 3.47.2 / Dart 3.13.2 — see the toolchain table in
[[MobileApp]]. The Platform badge also reads `Android | iOS`, while everything documented
in [[Release]] and `store_listing/` targets the Play Store and the web PWA; whether iOS is
still an intended target is worth settling in the same pass.

Worth a pass over the whole Tech Stack list rather than a one-line badge fix: the
dependency versions quoted there predate the Flutter 3.47 upgrade too.

**What closed it.** The whole README was rewritten rather than patched: badges (Flutter 3.47.2,
`Android | Web` — iOS settled as not a target), a tech stack split into app and backend with
Drift as the database and sqflite named as the bootstrap migrator only, the mandatory
`dart run build_runner build` step that was missing from Getting Started, the web PWA build,
the 10 languages, a Backend section stating plainly that the sync client does not exist, the
three CI jobs, and a corrected privacy section. Versions were cross-checked against
`pubspec.yaml` rather than carried over.

---

## There is no CI

**Status:** done (2026-09-09) — closed by the `chore/ci` branch. Opened 2026-09-09,
carried over from the Flutter 3.47 entry.

Nothing mechanically checked that a fresh clone builds, which was uncomfortable given
`*.g.dart` is gitignored. The backend already had three green gates (`ruff check`,
`mypy`, `pytest`) and the app had `flutter analyze` + `flutter test`; a workflow running
them costs little and stops lint debt from re-accumulating.

The Flutter 3.47 upgrade made this sharper: it turned out `android/settings.gradle` had
been shadowing `android/settings.gradle.kts` since the first commit, so edits to the `.kts`
file were silently dead. A build in CI would have caught that years earlier.

**Closed by `.github/workflows/ci.yml`** — three parallel jobs on every push to `main` and
every PR:

- `backend` — `uv sync --locked --extra dev`, then `ruff check .`, `mypy`, `pytest -v`.
  The full suite, so the `integration`-marked testcontainers test really starts
  `postgres:17-alpine` and exercises LISTEN/NOTIFY and JSONB — covered nowhere else.
  `uv` rather than `pip install -e ".[dev]"`, which silently misses `testcontainers` and
  `httpx-ws`: they live in `[dependency-groups]`, which pip does not read.
- `app` — `pub get` → `dart run build_runner build` → `analyze` → `test` → web release
  build. The codegen step is what makes this a fresh-clone proof.
- `android` — the same codegen, then `flutter build apk --debug`, plus an assertion that
  the Flutter tool really injected the gitignored `gradlew` / `gradle-wrapper.jar`.

Deliberately **not** covered, so the gap stays honest: the e2e suite
(`integration_test/app_test.dart`) is out, because it calls the real production endpoint;
the signed release APK/AAB is out, because it needs the keystore secrets; and `ruff format`
is not run, as it remains its own open item.

Two traps found while writing it. `gradle/actions/setup-gradle` is the wrong action here —
it expects a wrapper at checkout time, but `android/gradlew` is gitignored until Flutter
injects it, so `actions/setup-java` with `cache: gradle` does the job instead. And
`android/gradle.properties` asks for `-Xmx8G`, more than a runner has; the override goes in
the `GRADLE_USER_HOME` `gradle.properties`, which outranks the project's, so the committed
file stays untouched.

---

## Upgrade Flutter to 3.47 to unblock the held-back dependencies

**Status:** done (2026-09-09) — closed by the `chore/flutter-3-47` branch. Opened
2026-09-09 during the dependency update (`f0a8bd6`).

The trigger was a defect, not version lag: `dart run drift_dev <anything>` failed to
compile at drift 2.34.4 / drift_dev 2.34.0 (`The getter 'allSchemaEntities' isn't defined
for the type 'GeneratedDatabase'`). `drift_dev` 2.34.6 fixes it but needs
`analyzer >=13.0.0 <15.0.0`, and Dart 3.11 capped us at analyzer 10.0.1.

**Flutter 3.41.9 / Dart 3.11.5 → 3.47.2 / Dart 3.13.2**, and all seven held-back packages
moved: `drift_dev` 2.34.0→2.34.6, `build_runner` 2.15.1→2.16.1, `flex_color_picker`
3.8.0→4.0.0, `wakelock_plus` 1.7.0→1.8.0, `sqflite` 2.4.2+1→2.4.3, `intl` 0.20.2→0.20.3,
`sqflite_common_ffi` 2.4.0+3→2.4.2+1. `analyzer` went 10.0.1→14.3.0. `drift` itself stayed
at 2.34.4 — drift_dev 2.34.6 requires `drift <2.35.0`.

The CLI works again: `dart run drift_dev analyze` returns *No errors found*.

### What the entry got wrong about the web binaries

The old entry, `.llmwiki/Web.md` and `web/CLAUDE.md` all justified tracking
`web/sqlite3.wasm` and `web/drift_worker.js` with "the `make-web-worker` CLI is broken, so
the repo is the only reliable source". Both halves were wrong. `make-web-worker` is not a
`drift_dev` subcommand at all in 2.34.6, and the worker never needed a CLI: **drift ships
it prebuilt at its package root**. The files stay tracked, but now for the honest reason —
a fresh clone should not have to fetch binaries to run the PWA. Refreshing the stale
committed worker is its own `TODO.md` entry.

### `android/settings.gradle` had been shadowing `settings.gradle.kts` since the first commit

The first AGP 9 build failed with *"Your project's Android Gradle Plugin version (8.9.1) is
lower than Flutter's minimum"* — after `settings.gradle.kts` had been edited to 9.1.0. A
Groovy `android/settings.gradle` from `4e52a54` sat next to it pinning AGP 8.9.1 and Kotlin
**2.1.0**, and Gradle prefers the Groovy file when both exist. So every edit to
`settings.gradle.kts` had been dead — including the Kotlin 2.2.20 bump the old TODO
described as already applied. The Groovy file is deleted; the rest of the project is Kotlin
DSL. This is the strongest argument yet for the still-open "no CI" item.

### Android toolchain, aligned to Flutter 3.47.2's own templates

Gradle 8.12→9.3.1, AGP 8.9.1→9.1.0, Kotlin 2.1.0→2.4.0, compileSdk/targetSdk 35→36 (both
follow `flutter.*`), SDK Build-Tools 36.0.0 installed as an AGP 9 prerequisite. Flutter
hard-errors below Gradle 8.14 / AGP 8.11.1 / KGP 2.2.20 / Java 17, so the Android side
could not have been left alone regardless.

The AGP 9 migration itself is the three-line diff Flutter's own template makes:
`id("kotlin-android")` dropped from `android/app/build.gradle.kts` (Flutter's Gradle plugin
applies it), the `kotlinOptions` block replaced by a top-level
`kotlin { compilerOptions { jvmTarget = JVM_17 } }`, and `android.newDsl=false` +
`android.builtInKotlin=false` added to `android/gradle.properties` — AGP 9 defaults both to
`true`, and `org.jetbrains.kotlin.android` is incompatible with the new DSL.
`android.enableJetifier=true` was dropped: no Flutter template has ever set it, it only
rewrites pre-AndroidX artifacts, and it costs build time.

### Verification

`flutter analyze` clean · 37/37 `flutter test` · release apk and appbundle build with R8
enabled · web build serves and drift opens its database in the browser (`drift_worker.js`
fetched, IndexedDB `countscore` created, zero console errors) against the **committed**
worker.

On a Pixel 9 Pro XL (Android 17), because none of this has automated coverage:

- **flex_color_picker 4.0.0** — the one upgrade with real API exposure. Both the Primary/
  Accent/Wheel dialog and the wheel picker render correctly and preselect the current
  colour, matching the `pickersEnabled` map in `players_screen.dart`.
- **wakelock_plus 1.8.0** — toggling it acquires a real `SCREEN_BRIGHT_WAKE_LOCK`
  attributed to `com.vemore.countscore` in `dumpsys power`, and releases it on toggle off.
- **file_picker 12.2.0 + export** — the SAF directory picker opens and a full export
  completes end to end.

Not run: `integration_test/app_test.dart` on device, which needs `adb shell pm clear` and
so would destroy real game data; and the chromedriver web e2e, since chromedriver is not
installed. The Playwright runtime check above covers what the web e2e would have proved
about startup and persistence.

### Smaller consequences

- `build_runner` 2.16 **removed `--delete-conflicting-outputs`** — it now warns and ignores
  the flag. Dropped from `CLAUDE.md`, `.llmwiki/DataLayer.md` and the `db-migration` and
  `release-android` skills.
- Analyzer 14 raised two new findings on pre-existing code. `IconData(iconCodePoint, ...)`
  in `lib/models/game_type.dart` now warns `non_const_argument_for_const_parameter` — that
  warning *is* the dynamic-icon constraint surfacing, so it carries a targeted `// ignore:`
  with the reason rather than a hardcoded codepoint. `GameAnalysisScreen`'s private
  `_repository` field became public `repository`, which satisfies `prefer_initializing_formals`
  properly and keeps the injection seam usable from outside the library.
- Every Android build now warns that `shared_preferences_android` applies KGP. Upstream's
  to fix; tracked in `TODO.md`.
- `flutter analyze` on 3.47 rewrites `analysis_options.yaml` itself, printing *"Upgrading
  analysis_options.yaml to exclude build and platform directories"* and adding an
  `analyzer: exclude:` block for `build/`, `android/`, `ios/` and `web/`. The block is
  committed because reverting it just makes the next `flutter analyze` add it back.
- `android/.kotlin/` is a new Kotlin 2.4 build-artifact directory; added to
  `android/.gitignore`.

---

## `ThemeProvider` never persists

**Status:** done (2026-09-09) — closed by `ccc3640`, *fix: persist the selected theme
across restarts*. Surfaced during the LLM-wiki migration.

`lib/providers/theme_provider.dart` held `ThemeMode` in memory only, so the app reset to
`ThemeMode.system` on every restart. It now stores `ThemeMode.name` under the `themeMode`
key, and `main()` reads it before `runApp` rather than loading async in the constructor
the way `SettingsProvider` does — that pattern would have shown a light flash on every
cold start for a dark-mode user. The unused `toggleTheme()` and `isDarkMode` went with it.

---

## Backend security debt

**Status:** done (2026-09-09) — closed by `c14ff9c`, *feat(backend): harden the API, and
make ruff and mypy green*, recorded in `ef57989`. Surfaced during the LLM-wiki migration.

All five catalogued items are closed, plus four found while reading the code:
WebSocket ticket handshake, IP rate limit on group create/join, `share_token`
out of `GET /groups/me`, value bounds on `/sync/push`, security headers; and
the driver error leaked in sync rejections, the `--workers 2` default in the
Dockerfile, the `Content-Length` bypass of the body cap, and the one
string-built SQL statement in `notify.py`.

Details and the reasoning: `.llmwiki/Security.md`. What remains open is listed
there too — the unauthenticated `/comments` endpoints, the O(N) argon2 scan,
and the absence of an owner role on `Device`.

---

## Backend lint debt and type checking

**Status:** done (2026-09-09) — closed by `c14ff9c`, *feat(backend): harden the API, and
make ruff and mypy green*. Surfaced during the LLM-wiki migration.

`ruff check .` in `backend/` is clean, and `mypy` is now configured
(`[tool.mypy]` in `backend/pyproject.toml`) and clean over the 36 source files.
The SQLModel query expressions were rewritten with `sqlmodel.col()` rather than
having the error codes silenced, so the checker still reads those lines.

`openai` is unpinned from `>=2,<3` to `>=3,<4` (3.10.0). The only breaking
change in 3.0 was httpx2 as the default client, which `openai_compat.py` never
touched — and `anthropic` 1.4 was already on httpx2, so the tree converged.

Note: `ruff format` has still **never** been run on `backend/` — that stays open in
`TODO.md`.
