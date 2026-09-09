# TODO

Open work only. A finished item moves to `DONE.md` — see the workflow section of
`CLAUDE.md`.

## The Flutter sync client does not exist

**Status:** open — noted 2026-09-09, during a branch/commit review.

Milestones 5 to 7 are marked Done in `.llmwiki/Architecture.md`, and on the server they
are: groups, delta-log sync with per-field LWW, and `/sync/stream` over Postgres
LISTEN/NOTIFY are implemented and tested. **Nothing in the app consumes any of it.**

`lib/services/sync_service.dart` and `lib/services/backend_client.dart` are referenced by
the documentation but are not on disk — `lib/services/` holds only `database_service.dart`,
`drift/` and `uuid.dart`. The single file in `lib/` that makes a network call is
`lib/screens/game_analysis_screen.dart`, for the ZapZap analysis.

So the backend is a working service with no client, and both the mobile app and the PWA are
still purely local. This is the largest gap between what the wiki says the project is and
what it does, and it is the thing that would make group sharing real.

It needs its own design pass, not a quick patch: an outbox on the Drift side, conflict
handling that matches the server's LWW rules, device-token storage, and a reconnect policy
for the WebSocket. See [[Sync]] and [[Architecture]].

## There is no CI

**Status:** open — noted 2026-09-09, carried over from the Flutter 3.47 entry.

Nothing mechanically checks that a fresh clone builds, which is uncomfortable given
`*.g.dart` is gitignored. Now that the backend has three green gates (`ruff check`,
`mypy`, `pytest`) and the app has `flutter analyze` + `flutter test`, a workflow running
them costs little and would stop lint debt from re-accumulating.

The Flutter 3.47 upgrade made this sharper: it turned out `android/settings.gradle` had
been shadowing `android/settings.gradle.kts` since the first commit, so edits to the `.kts`
file were silently dead. A build in CI would have caught that years earlier.

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
