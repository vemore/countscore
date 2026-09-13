# TODO

Open work only. A finished item moves to `DONE.md` — see the workflow section of
`CLAUDE.md`.

## `_snack` hardcodes `Colors.green` / `Colors.red`

**Status:** open — noted 2026-09-11, while fixing the section-header colours in the same file.

`lib/screens/settings_screen.dart:28-33` picks its snackbar background from
`ok ? Colors.green : Colors.red` — the same theme-blindness just fixed four lines below, in the
section headers. Saturated red and green sit badly on the dark theme's surfaces and ignore the
scheme entirely.

The analysis screen's new failure snackbar uses `Theme.of(context).colorScheme.error`, so the
two now disagree about what a failure looks like. The fix is `colorScheme.error` /
`onError` for the failure case and `colorScheme.primary` (or a tertiary) for the success one,
across the six `_snack` call sites. Not folded into the header fix because it changes the look
of every settings confirmation, not just a label colour.

## The Flutter sync client does not exist

**Status:** open — noted 2026-09-09, during a branch/commit review.

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

## Backend security review — 2026-09-13

**Status:** open — noted 2026-09-13, during a cyber-security review of `backend/` requested
by the user. Nothing below was fixed; the items are ordered by severity, each with the
evidence and the proposed fix. The three HIGH items were **confirmed by running
proof-of-concept tests** against the project's own SQLite fixtures (`tests/conftest.py`);
the PoC file is not committed because it asserts the *presence* of the flaws — the results
quoted below are the acceptance criteria to invert when each fix lands. Everything the
2026-09-09 audit closed (`DONE.md`) was re-checked and holds; the debt it left open is
still in `.llmwiki/Security.md` and is not repeated here.

Checked and found fine, so nobody re-audits them: SQL parameterised throughout; CORS is an
explicit list with credentials off; body cap with 411 on chunked; security headers and CSP;
secrets in env only, and none in git history (grepped for `sk-ant-`, `AKIA`, `AIza`); the
database not published; the API bound to `127.0.0.1`; the WS ticket redeemed before
`accept()`; the PWA mount refusing traversal; argon2 on device tokens; `share_token` kept out
of routine reads.

### HIGH — Cross-group data tampering through `POST /sync/push`

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

### HIGH — Every per-IP rate limit is bypassed by a client-supplied `X-Forwarded-For`

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

### HIGH — The O(N) argon2 scan is an unauthenticated CPU denial of service

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

### MEDIUM — `POST /comments/zapzap-analysis` takes an unvalidated `dict` and is an open LLM proxy

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

### MEDIUM — Revocation is reversible by the revoked party

`POST /groups/join` returns `share_token` to the joiner (`backend/app/routes/groups.py:132`),
so every device holds it for good. Revoking a device (`groups.py:171`) without rotating the
token lets the revoked device re-join at once and get a fresh token. Proposed: rotate
`share_token` inside `revoke_device` and return the new one, as `rotate-share-token` does —
or, at minimum, document in `.llmwiki/Api.md` that a revoke is meaningless without a rotate.
Belongs with the owner-role debt already listed in `.llmwiki/Security.md`.

### MEDIUM — One Postgres connection per WebSocket, no per-device cap

`backend/app/services/notify.py:49` opens a dedicated `asyncpg.connect` for every
`/sync/stream`, and `POST /sync/ws-ticket` has no rate limit. One authenticated device can
open hundreds of streams and exhaust Postgres `max_connections` (default 100, of which the
app's own pool wants 30) — a service-wide outage from inside one household. Proposed: a
single shared LISTEN connection with an in-process fan-out (`dict[group_id, set[Queue]]`),
and a cap of about three concurrent streams per device.

### MEDIUM — Any member may raise the group's LLM budget to 10 000 ¢ a month

`backend/app/schemas/groups.py:60` lets `PATCH /groups/me/settings` set
`monthly_budget_cents` up to 10 000; the operator only controls the *initial* value through
`DEFAULT_BUDGET_CENTS`. Proposed: a `MAX_BUDGET_CENTS` setting — an operator-owned ceiling,
defaulting to `DEFAULT_BUDGET_CENTS` — enforced in the route, and listed in
`.env.example` and `.llmwiki/Deployment.md`.

### LOW — No rate limit on authenticated writes; the raw payload is persisted and replayed

`/sync/push` stores `delta.payload` verbatim in `change_log` (`sync.py:291`), unknown keys
included, up to 256 KiB per request and 500 deltas, and `/sync/pull` serves it back to every
member. A member can bloat the NAS disk and every sibling device. Proposed: persist only the
coerced, known columns; a per-device limiter on `/sync/push` (reuse `check_and_increment`
with a scope of its own). Also `list_comments` (`backend/app/routes/comments.py:349`) takes
`limit: int = 10` unbounded — a negative value is a Postgres error and a 500:
`Query(ge=1, le=100)`.

### LOW — Hardening bundle

None of these is exploitable on its own; together they are the usual production checklist.

- `/docs`, `/redoc` and `/openapi.json` are public in production, under a CSP that allows
  `'unsafe-inline'`: `docs_url=None` unless an `EXPOSE_DOCS` setting is true.
- `backend/Dockerfile` runs as root, keeps `build-essential` in the final image, and
  installs from `pyproject.toml` — not from `uv.lock`, which only CI honours
  (`uv sync --locked`), so production resolves its own dependency set. Multi-stage build,
  a `USER`, and `uv sync --locked --no-dev`.
- No dependency vulnerability scan anywhere: a `pip-audit` (or `uv` equivalent) step in
  `.github/workflows/ci.yml` and a `.github/dependabot.yml`.
- `AsyncOpenAI` and `AsyncAnthropic` are built without a timeout (600 s by default) while
  the app gives up after 90 s: pass `timeout=90`, as `bedrock.py` already does.
- `f"invalid payload: {e}"` (`comments.py:141`) echoes internal key names to the client, and
  `logger.warning("... %s", e.orig)` in `sync.py:181` writes driver error text containing
  user data — newlines included — to the log. Generic detail out; sanitise before logging.
- The daily backups (`./backups`, plain gzip) hold every live `share_token`: say so in
  `.llmwiki/Deployment.md`, or encrypt them.

### Not security: `server_seq` can collide under concurrent pushes

`_next_server_seq` (`backend/app/routes/sync.py:115`) is `max + 1` inside the transaction
with no lock, and `ix_change_log_group_seq` is not unique, so two pushes in the same group
at the same moment can share a `server_seq` — and a puller paging with `> since_seq` can
skip one of them. Same class as the dedup index: a concurrent retry of one delta hits the
unique `(origin_device_id, client_lamport)` index and comes back as a 500 instead of
`duplicate`. Fix: `SELECT … FOR UPDATE` on the group row (or a per-group sequence) and a
unique index on `(group_id, server_seq)`; catch the dedup `IntegrityError`.

## `shared_preferences_android` still applies the Kotlin Gradle Plugin

**Status:** open — noted 2026-09-09, during the Flutter 3.47 upgrade.

Every Android build now prints:

```
WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP):
shared_preferences_android
Future versions of Flutter will fail to build if your app uses plugins that apply KGP.
```

Nothing to do on our side — it needs an upstream release that migrates to AGP's built-in
Kotlin. Watch the `shared_preferences` changelog; this becomes a hard build failure on some
future Flutter, not on 3.47.2.

## The web e2e recipe assumes a matching `chromedriver` on the PATH

**Status:** open — noted 2026-09-13, while running the web e2e for the drift worker refresh.

`.llmwiki/Testing.md` says "`chromedriver --port=4444 &`" and that its major version must
match Chrome. On the development machine there is no `chromedriver` on the PATH; the copy
under `~/cft/` is 145 while Chrome is 153, so the recipe fails as written. It took a manual
lookup in the Chrome for Testing `known-good-versions-with-downloads.json` and a download of
the matching `chromedriver-linux64.zip` into the session scratchpad to run the suite.

Proposal: a small `scripts/chromedriver.sh` that reads `google-chrome --version`, fetches
the matching Chrome for Testing driver into a cache directory if absent, and starts it on
4444 — and point the Testing recipe (and `.claude/rules/web.md`) at it instead of a bare
`chromedriver`.

---

## Surfaced during the LLM-wiki migration

**Status:** open — noted 2026-09-09, while decomposing `CLAUDE.md` and `ARCHITECTURE.md`
into `.llmwiki/`. None of these were introduced by that change; they were found by reading
the whole tree at once. Background for each lives in the wiki page named alongside it.

### Smaller, self-contained

- **`test/widget_test.dart` pumps no widgets.** Its 8 tests are model serialisation. The
  name implies widget coverage that does not exist anywhere in the repo — rename it, or
  give it real widget tests.
- **The Drift repositories are raw SQL.** `drift_repositories.dart` uses `customSelect` /
  `customInsert` throughout, a faithful port of the sqflite queries. That was the right
  call for a safe migration, but the type-safe-query argument for adopting Drift is still
  unbanked. Converting the simplest repositories first would prove the pattern.
