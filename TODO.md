# TODO

Open work only. A finished item moves to `DONE.md` — see the workflow section of
`CLAUDE.md`.

## `GEMINI_MODEL` defaults to a model that is quota-0 on the free tier

**Status:** open — noted 2026-09-11, while closing the Mistral default.

`gemini_model: str = "gemini-2.5-pro"` (`backend/app/config.py:32`), duplicated as
`${GEMINI_MODEL:-gemini-2.5-pro}` in `docker-compose.prod.yml:40`. On a free-tier Google key
`gemini-2.5-pro` has a quota of **0**, so switching `LLM_PROVIDER=gemini` without also setting
`GEMINI_MODEL` fails immediately — exactly the class of trap just closed for Mistral, on the
provider next door. `gemini-2.5-flash` works without billing enabled.

Not fixed inline because nothing currently runs on gemini, and because picking the default is
the same product decision the Mistral one was. When it is fixed, remember the default lives in
**two** tracked places, and the compose one wins in production.

## Backend tests read the developer's local `backend/.env`

**Status:** open — noted 2026-09-11, found when a new `/health` test passed in CI's shape and
failed locally.

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

**Status:** open — noted 2026-09-11, while setting up an on-device test of the configurable
backend URL.

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

## The analysis footer sits under the navigation bar

**Status:** open — noted 2026-09-11, seen on the Pixel 9 Pro XL.

`lib/screens/game_analysis_screen.dart` ends its `SingleChildScrollView` with
`padding: EdgeInsets.fromLTRB(16, 16, 16, 32)` and no `SafeArea`. Scrolled to the bottom, the
"Généré le … · <model>" line is drawn behind the system gesture bar and is partly unreadable.
32 logical pixels is less than the bottom inset on this device.

Fix: wrap the body in a `SafeArea(bottom: true)`, or add
`MediaQuery.viewPaddingOf(context).bottom` to that padding. Pre-existing; the footer has
always been there.

## A failed regeneration hides the cached analysis until you leave the screen

**Status:** open — noted 2026-09-11, seen while testing against the production backend, which
currently 502s (see the Mistral item below).

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

## Section headers are hardcoded `Colors.deepPurple`, which is weak in dark mode

**Status:** open — noted 2026-09-11, seen on the Pixel 9 Pro XL in dark mode.

Every section header in `lib/screens/settings_screen.dart` ("Apparence", "Serveur", "Écran",
"Sauvegarde") uses `color: Colors.deepPurple` rather than a colour from the scheme. On black
that purple is a low-contrast, saturated blue-violet. The Server section added on 2026-09-11
copied the existing style rather than diverge from its neighbours, so the fix is one change
across all four: `Theme.of(context).colorScheme.primary`.

## The NAS hostname is still in git history

**Status:** open — noted 2026-09-11, while making the backend URL configurable.

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

## The ZapZap analysis is down in production: Mistral rejects the configured model

**Status:** open — noted 2026-09-09. **Code half landed 2026-09-11** on
`fix/zapzap-mistral-and-analysis-ui`; what remains is the production environment, below.

`POST /comments/zapzap-analysis` returns **502** for every request, on every client, because
production runs `LLM_PROVIDER=mistral` and inherits a code default the account's tier rejects:

```
RuntimeError: mistral API call failed: PermissionDeniedError: Error code: 403 -
{'message': 'This model is not available in your subscription tier',
 'type': 'tier_not_allowed', 'code': '1910'}
```

### Done on 2026-09-11

- The default is `mistral-medium-latest` in **all five** tracked places. The original entry
  said the fix was one line of production environment; that was wrong. The default lives in
  `app/config.py:37` **and** in `docker-compose.prod.yml:38` as `${MISTRAL_MODEL:-…}`, and the
  compose value wins in production — a default changed in `config.py` alone never reaches the
  container. Plus `.env.example` twice and `backend/README.md`.
- `GET /health` now reports the resolved provider and model
  (`{"llm": {"provider", "model", "credentials"}}`), built without calling the provider, so a
  misconfigured deploy is visible from one free request. It stays 200 when the provider is
  unresolvable, because failing the probe would restart-loop a container whose group and sync
  routes are fine.
- `test_health.py` pins that shape, including the unknown-provider case;
  `test_factory_returns_mistral_from_env` gained the `provider.model` assertion it was missing
  — the hole the outage went through.

### Still open

**The production container has not been touched.** Until `MISTRAL_MODEL` is set on the NAS, or
the new image is deployed, every analysis still 502s. See §2 of the `backend-deploy` skill for
the in-place procedure, then verify with a real `POST` — only that proves the account's tier
allows `mistral-medium-latest`. If it 403s too, `mistral-small-latest` is the fallback.

**Nothing watches the failure.** `/health` now makes a *misconfiguration* visible, but nothing
alerts on a 502 rate, and nothing would notice the provider refusing calls again. That is how
this survived two days. See [[LlmProviders]] and [[KnownLimits]].

## The ZapZap system prompt hard-codes eight real people's names

**Status:** open — noted 2026-09-09, while tracing the analysis payload for the data safety
pass.

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
([[SchemaV9]]), so that reindexes the whole statistics history. Options worth costing —
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
project with no CI and no backend alerting.

Two cheap prerequisites fall out of the above and can be done independently:

- Extract a `BackendClient` from `lib/screens/game_analysis_screen.dart`. It is useful on
  its own, and it removes a raw network call from a screen — which the `Code style` rule in
  `CLAUDE.md` forbids.
- Land CI before the client, not after (see the CI entry below).

## The sync conflict branch has no test

**Status:** open — noted 2026-09-09, while reviewing the sync-client entry.

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

## `ruff format` has never been run on `backend/`

**Status:** open — noted 2026-09-09, carried over from the Flutter 3.47 entry.

It would rewrite 43 of 50 files. Left out of the 2026-09-09 backend pass on purpose, so
the functional diff stayed readable. It wants its own `chore:` commit.

## Refresh the committed `web/drift_worker.js`

**Status:** open — noted 2026-09-09, found while verifying the drift_dev CLI.

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

## `web/CLAUDE.md` is published with the PWA

**Status:** open — noted 2026-09-09, spotted while runtime-checking the web build.

Flutter copies everything under `web/` into the build output, so `build/web/CLAUDE.md`
ships to whoever serves the PWA — internal instructions on a public URL. Harmless today,
but it should either move out of `web/` or be stripped by whatever deploy step the PWA
eventually gets (see "The Flutter web app has no deployment path" below).

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

---

## Surfaced during the LLM-wiki migration

**Status:** open — noted 2026-09-09, while decomposing `CLAUDE.md` and `ARCHITECTURE.md`
into `.llmwiki/`. None of these were introduced by that change; they were found by reading
the whole tree at once. Background for each lives in the wiki page named alongside it.

### The Flutter web app has no deployment path

`.llmwiki/Deployment.md` covers the FastAPI container completely. For the PWA there is
nothing: no vhost, no Web Station config, no deploy script, no documented `--base-href`.
The app is built and served by hand. Whoever deploys it next has to rediscover how.
See `.llmwiki/Web.md`.

### Smaller, self-contained

- **`test/widget_test.dart` pumps no widgets.** Its 8 tests are model serialisation. The
  name implies widget coverage that does not exist anywhere in the repo — rename it, or
  give it real widget tests.
- **The Drift repositories are raw SQL.** `drift_repositories.dart` uses `customSelect` /
  `customInsert` throughout, a faithful port of the sqflite queries. That was the right
  call for a safe migration, but the type-safe-query argument for adopting Drift is still
  unbanked. Converting the simplest repositories first would prove the pattern.
