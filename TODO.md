# TODO

Open work only. A finished item moves to `DONE.md` — see the workflow section of
`CLAUDE.md`.

## Release builds declare no `INTERNET` permission, so the analysis cannot work

**Status:** open — noted 2026-09-09, while checking permissions for the data safety guide.

`android/app/src/main/AndroidManifest.xml` declares **no permissions at all**. `INTERNET`
appears only in `android/app/src/debug/AndroidManifest.xml` and the profile manifest, where
Flutter's template puts it for hot reload. Confirmed against a merged release manifest built
today: `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`
contains one `uses-permission`, the generated `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, and
no `INTERNET`.

So **the ZapZap analysis cannot work in a signed release build** — the HTTP POST in
`lib/screens/game_analysis_screen.dart` will fail with a `SocketException`. It works in debug
and profile, which is why it has not been noticed: the e2e device run described in
[[Testing]] drives a debug build.

The fix is one line in the main manifest:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

It is filed rather than applied because it is a shipping-behaviour change that belongs with a
release, needs verification against the merged manifest (not the source one), and must land in
the same release as the updated Play Store data safety declaration — see
`PLAY_STORE_DATA_SAFETY.md`, which documents it as a prerequisite. Declaring transmission on
the form while the binary cannot transmit, or shipping the permission while the form still
says nothing is collected, are both worse than either change alone.

Worth checking on the same pass whether the release build should reach the network at all
before the sync client exists, and whether the e2e suite should run against a release build
so this class of bug is caught mechanically.

## The Flutter sync client does not exist

**Status:** open — noted 2026-09-09, during a branch/commit review.

Milestones 5 to 7 are marked Done in `.llmwiki/Architecture.md`, and on the server they
are: groups, delta-log sync with row-level LWW, and `/sync/stream` over Postgres
LISTEN/NOTIFY are implemented and tested. **Nothing in the app consumes any of it.**

`lib/services/sync_service.dart` and `lib/services/backend_client.dart` are referenced by
the documentation but are not on disk — `lib/services/` holds only `database_service.dart`,
`drift/` and `uuid.dart`. The single file in `lib/` that makes a network call is
`lib/screens/game_analysis_screen.dart`, for the ZapZap analysis.

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

## `.llmwiki/Testing.md` is missing a test file

**Status:** open — noted 2026-09-09, spotted while running the gates for the Flutter 3.47
upgrade.

Its table lists four files totalling 30 tests. `flutter test` runs **37** across six files:
`test/providers/theme_provider_test.dart` (added by `ccc3640`) was never added to the page.
Not introduced by the SDK upgrade — just visible from running the suite.

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

### `PUBLISHING.md` predates the backend

It describes a purely local, offline app. Any release shipping group sharing or LLM
commentary needs the Play Data Safety declaration rewritten first, to disclose the network
calls and what game data leaves the device. `PLAY_STORE_DATA_SAFETY.md` and
`privacy_policy.md` need the same pass. **This blocks the next store release**, not the next
commit. See `.llmwiki/Release.md` and `.llmwiki/Security.md`.

### Smaller, self-contained

- **`test/widget_test.dart` pumps no widgets.** Its 8 tests are model serialisation. The
  name implies widget coverage that does not exist anywhere in the repo — rename it, or
  give it real widget tests.
- **The Drift repositories are raw SQL.** `drift_repositories.dart` uses `customSelect` /
  `customInsert` throughout, a faithful port of the sqflite queries. That was the right
  call for a safe migration, but the type-safe-query argument for adopting Drift is still
  unbanked. Converting the simplest repositories first would prove the pattern.
