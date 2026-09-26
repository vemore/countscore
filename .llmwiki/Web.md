# Web

> Scope: everything specific to the PWA build.
> Related: [[DataLayer]] · [[MobileApp]] · [[Testing]] · [[LlmProviders]] · [[KnownLimits]]
> Updated: 2026-09-26

## Facts

### What is in `web/`

`index.html` (the **stock Flutter template** — `$FLUTTER_BASE_HREF`, `flutter_bootstrap.js
async`, no service-worker code — with real metadata: title and apple title "CountScore", a
description, `<meta name="theme-color" content="#0E8F88">`) · `manifest.json` (CountScore,
standalone, portrait-primary, `theme_color` `#0E8F88`, the light theme's brand teal
`kBrandSeedLight`, `lib/utils/app_theme.dart:9`) · **`flutter_bootstrap.js`**, the stock
loader template plus `fontFallbackBaseUrl` (below), without its `serviceWorkerSettings`, and
with the registration of ours · **`service_worker.js`**, CountScore's service worker ("Offline
and updates", below) · **`fallback-fonts/OFL.txt` and
`LICENSE-Apache-2.0.txt`**, the licences of the mirrored fallback fonts · `favicon.png` ·
`icons/` (4 PNGs) · the two Drift runtime binaries: **`sqlite3.wasm` (748686 B, sqlite3 3.6.0)** and
**`drift_worker.js` (357220 B, the prebuilt worker from drift 2.35.0)** · and
`sqlite3.wasm.sha256`, 279 B, the `sha256sum -c` file that records which release the wasm
came from.

Nothing else belongs in `web/`: Flutter copies the whole directory into `build/web/`, so
any file placed there is published — the `.sha256` included, which is why it is 279 bytes
and not a document. The Claude Code instructions for the PWA live in `.claude/rules/web.md`
for that reason.

### The committed binaries are checked against `pubspec.lock`

`scripts/web_binaries.sh` compares both, and runs as a step of the `app` CI job right after
`flutter pub get` (`.github/workflows/ci.yml`), so a dependency bump that leaves a binary
behind fails a required check instead of merging green — see [[Testing]].

| Binary | Source | How it is checked |
|---|---|---|
| `drift_worker.js` | the drift package root, `$PUB_CACHE/hosted/pub.dev/drift-<locked>/` | `cmp`, offline |
| `sqlite3.wasm` | a `sqlite3.dart` GitHub release asset — in no package | `web/sqlite3.wasm.sha256`, offline; `--fetch` also compares the upstream asset |

`--check` (default) is offline and costs ~20 ms. `--fetch` adds the upstream comparison and
runs in CI on the weekly `schedule:` only. `--refresh` copies the worker, downloads the wasm
into a temp directory, validates its `0061736d` magic, copies it in and rewrites the
`.sha256`; it never `mv`s, and it is finished only once the web e2e has run. Exit codes are
`0` match, `1` a real disagreement, `2` usage, `3` environment — a scheduled `--fetch`
tolerates `3` and never `1`.

`web/sqlite3.wasm.sha256` carries its version as its own `# version:` key, cross-checked
against `# source:`, because `sqlite3` is **transitive**: nothing proposes a bump for it, so
the recorded version disagreeing with the lock is the whole point of the file.

### Persistence

`lib/services/drift/connection/connection_web.dart`:

```dart
driftDatabase(
  name: 'countscore',
  web: DriftWebOptions(
    sqlite3Wasm: Uri.parse('sqlite3.wasm'),
    driftWorker: Uri.parse('drift_worker.js'),
  ),
).interceptWith(PersistenceFlushInterceptor())
```

SQLite compiled to wasm, persisted through OPFS (IndexedDB fallback) by `drift_flutter`.

> **Status: Outdated** (2026-09-19) — in practice the PWA is on **IndexedDB**, not OPFS.
> drift probes the browser and, in Chromium without cross-origin isolation (no COOP/COEP
> headers — the backend's own host, GitHub Pages and a local build alike), logs `Using
> WasmStorageImplementation.sharedIndexedDb due to missing browser features:
> {dedicatedWorkersInSharedWorkers, sharedArrayBuffers}`. The file then lives **in memory
> in a shared worker** and reaches the IndexedDB database `countscore` (stores `files` and
> `blocks`, 4096-byte blocks) only when the worker flushes.

**drift 2.35.0 flushes only after a statement run outside a transaction.** Its
`_WasmDelegate` skips the flush while `isInTransaction` is set, and a `COMMIT` runs before
that flag is cleared; the `PRAGMA user_version` it writes once migrations have run is not
flushed at all. So a committed transaction (deleting a game) and the schema version stayed in
memory until some later non-transactional write happened to flush them, and were lost on a
reload that came first: `user_version` read 0, `onCreate` ran again on a full database, and
deleted games came back. `PersistenceFlushInterceptor`
(`lib/services/drift/connection/persistence_flush.dart`) closes both holes by running `SELECT
1` outside any transaction after the first open and after each outermost transaction (a
batch included) — any flush writes every pending page, so what a call wrote is in IndexedDB
by the time it returns. `integration_test/reload_persistence_test.dart` reads IndexedDB back as the next page
load would, and fails on both counts without the interceptor. Seeding in `onCreate` is
idempotent as well, so a browser already stuck at version 0 completes `onCreate` once and
recovers on its first load of the fixed build (checked in Chromium: old build, reload,
new build → `user_version` 16, no uncaught error).

**Those explicit URIs are load-bearing.** Without them, drift_flutter 0.3.0 throws
`ArgumentError` at startup and the PWA crashes — while the *build* still passes clean. If
the web app dies on launch with nothing wrong at compile time, look here first.

There is no legacy database on web, so `bootstrapMigrate()` never runs: Drift's `onCreate`
builds schema v9 directly. See [[DataLayer]].

> **Status: Outdated** (2026-09-13) — `onCreate` builds the current schema (v11), and a
> browser that already holds a database from an earlier PWA release upgrades through Drift's
> `onUpgrade`. See [[Schema]].

Group sync works in the PWA as on Android: `flutter_secure_storage` keeps the device token
encrypted in localStorage, and the stream is `ws(s)://` on the configured server, allowed by
`connect-src 'self' https: wss:`. Verified on 2026-09-13 with two browser contexts against a
local backend serving the PWA on its own host: create, join, share, and a score entered in
one appearing on the other's open board within seconds.

### Feature guards

`kIsWeb` guards one feature in Settings, plus the review prompt and the conditional export
in `connection.dart`:

- `lib/providers/settings_provider.dart` — `supportsDbExportImport => !kIsWeb`, and
  export/import throw `UnsupportedError` on the web: they need `dart:io`.
- `lib/screens/settings_screen.dart` — reads `supportsDbExportImport` (not `kIsWeb`, so a
  widget test can play the web build) and drops the Backup heading **with** its rows.
  Every section heading there is a `_SectionTitle` followed by at least one row; the list
  pads its bottom with `withBottomInset` plus 16, so the last row clears the gesture
  bar (`test/screens/settings_screen_test.dart`).
- `lib/services/review_prompt.dart` — no Play review sheet in a browser.
- `lib/main.dart` — a configuration QR's `#/join?…` route is read out of the address bar
  before `runApp` (`lib/services/join_link_location_web.dart`, `dart:js_interop`; the
  native stub reads nothing), and in an Android browser the PWA offers the app before its
  replace dialog (`offerAppHandOver`). [[ConfigShare]] *What opens a link*.

**Keep screen awake works in the PWA.** wakelock_plus 1.8.0's web plugin injects
`assets/packages/wakelock_plus/assets/no_sleep.js` as a same-origin `<script>` (allowed by
`script-src 'self'`) and calls `navigator.wakeLock.request('screen')`, which no CSP
directive governs; it re-requests the lock on `visibilitychange`, since a browser drops it
when the tab is hidden. The API needs a secure context (https, or `localhost`). A browser
without `navigator.wakeLock` gets NoSleep's fallback — a looping `data:` video — which the
PWA's `default-src 'self'` blocks as media, so there the switch is saved but holds nothing;
the failure lands in the provider's `catch`. Verified on 2026-09-19 in Chromium at 412×860
under `_PWA_CSP` (`backend/app/main.py:38`): the switch obtains a `WakeLockSentinel`
(`type: screen`), turning it off releases it, the setting is re-applied after a reload, and
no CSP violation is logged. The lock is applied when `SettingsProvider` is first read — it
is a lazy provider (`lib/main.dart:53`) — as on Android.

**Sharing a result works in the PWA.** share_plus 13.3.0's web plugin calls
`navigator.canShare` / `navigator.share` (the Web Share API, which no CSP directive
governs) and, where the API is missing or refuses, falls back to opening a `mailto:` with
the subject and the text through url_launcher — a navigation, which the CSP does not govern
either. Verified on 2026-09-19 in Chromium at 412×860, a share_plus probe served under
`_PWA_CSP` (`backend/app/main.py:38`): with no Web Share API (desktop Linux Chromium) the
`mailto:?subject=…&body=…` handler launched; with the API present (stubbed) `navigator.share`
received the title and text with user activation still active; no CSP violation in either
case. The API needs the transient user activation, which is time-based (Chromium and Firefox
keep it 5 s after the tap), so what runs before `navigator.share` must stay short.

> **Status: Outdated** (2026-09-19) — `ShareResultButton` now draws the standings' PNG before
> it shares (`feat/share-result-image`). Probed the same day in Chromium at 412×860 under
> `_PWA_CSP` (a release build of `renderWidgetToPng` + `systemShareResult`): the 1200 px PNG
> (46 KB) was drawn in about 200 ms, and `navigator.share` received the text, the title and
> `countscore-result.png` (`image/png`) about 270 ms after the tap with the user activation
> still active; no CSP violation (the `File` is built from bytes, no `blob:` or `data:` URL
> is loaded). With `navigator.canShare` refusing files, share_plus threw (its download
> fallback is off), and the text alone was shared, still with the activation. Safari's
> activation window was not measured; if it proves shorter, pre-drawing the card when the
> screen opens is the fallback.

**Game sounds should work in the PWA, under the current CSP.** audioplayers 6.8.1's web
side (`audioplayers_web` 5.3.0) plays an asset by first fetching
`assets/assets/sounds/<name>.wav` from the app's own origin with `http` (allowed by
`connect-src 'self'`), then setting that same URL as the `src` of an `HTMLAudioElement`
(media falls under `default-src 'self'`); no `blob:` or `data:` URL is involved, so
`_PWA_CSP` (`backend/app/main.py:38`) needs no change. Browsers refuse audio before a user
gesture; every sound follows one (a keypad tap, the timer's Start). A browser that refuses
anyway lands in `GameSounds.play`'s catch. This was read from the package source on
2026-09-24, not yet heard in a browser: the setting is off by default.

### Building

```bash
scripts/build_web.sh                  # [--base-href=/subpath/] [other flutter build web args]
```

It runs `flutter build web --release --no-tree-shake-icons --no-web-resources-cdn` and then
mirrors the fallback fonts (next section). A bare `flutter build web` still compiles, but
`scripts/check_web_build.sh` refuses to publish it.

`--dart-define=BACKEND_URL=<url>` is optional and seeds the runtime setting only on a
profile that has never configured a server — see [[LlmProviders]]. CI passes no such flag.

`--no-tree-shake-icons` applies to web exactly as it does to apk — see [[MobileApp]].
Add `--base-href=/subpath/` if not served from the domain root.

The build writes `build/web/version.json` (name, version, build number from `pubspec.yaml`).
`package_info_plus` fetches it same-origin, relative to the base href, to show the version on
the About screen — so it must be published with the rest of `build/web/`; `connect-src 'self'`
already allows it.

There is **no committed hosting configuration for the Flutter web app** — no nginx or
Caddy vhost anywhere in the repo. [[Deployment]] covers only the FastAPI container.

> **Status: Outdated** (2026-09-13) — the backend container serves the PWA under
> `PWA_BASE_PATH` on its own host, and `scripts/deploy_web.sh` publishes the build; see
> [[Deployment]] and the `web-deploy` skill. Same origin as the API, so the CORS caveat
> below does not apply to that deployment. The
> drift URIs in `connection_web.dart` are relative, so they follow `--base-href`: checked
> by serving a `--base-href=/countscore/` build under that path — from a plain static
> server and from uvicorn with the PWA CSP — creating a game and reloading.

### Self-hosted web resources — no request to Google

A stock release build makes every visitor's browser call Google: CanvasKit (`canvaskit.js`
and its wasm) from `www.gstatic.com/flutter-canvaskit/<engine>/`, and fonts from
`fonts.gstatic.com/s/` — the engine's default fallback **Roboto on every start** (it is
downloaded unless a font family named `Roboto` is bundled), then a Noto font for each glyph no
registered font has. With Nunito as the only bundled face, that is every Chinese, Japanese,
Arabic and Devanagari string of the ten languages, most symbols, and any emoji a player types
in a name. Since 2026-09-19 none of it leaves the serving host:

- **CanvasKit** — `--no-web-resources-cdn` copies `canvaskit/` into the build and writes
  `"useLocalCanvasKit":true` into the loader's build config.
- **Fonts** — the engine reads `fontFallbackBaseUrl` from the loader config (default
  `https://fonts.gstatic.com/s/`). `web/flutter_bootstrap.js` sets it to `"fallback-fonts/"`,
  relative, so it follows the base href. `scripts/build_web.sh` reads every font path the
  compiled engine can ask for straight out of `build/web/main.dart.js` (quoted
  `<family>/v<n>/<file>.woff2` strings: 725 with Flutter 3.47.2 — 724 Noto files, CJK split
  into ~100 slices per family, plus Roboto), downloads the ones not yet in
  `$COUNTSCORE_FONT_CACHE` (default `~/.cache/countscore/fallback-fonts`; the paths are
  versioned and immutable) from `fonts.gstatic.com` — on the build machine, never in a
  visitor's browser — checks each is a `wOF2` file, and copies them to
  `build/web/fallback-fonts/<same path>`. About 22 MB on the server; a visitor still downloads
  only the few slices its text needs, lazily, exactly as it did from Google. The list comes
  from the build itself, so an SDK upgrade that changes the table needs no edit here.
- **Licences** — the Noto files are under the OFL 1.1 and Roboto under Apache 2.0; both texts
  are committed in `web/fallback-fonts/` and travel with the fonts.
- **The gate** — `scripts/check_web_build.sh` (both publishing paths, and the `app` CI job)
  refuses a build with no `canvaskit/canvaskit.wasm`, no `useLocalCanvasKit`, a loader that
  does not set `fontFallbackBaseUrl: "fallback-fonts/"`, or any font path of `main.dart.js`
  missing under `fallback-fonts/`. `_PWA_CSP` allows no Google host any more, so a regression
  on the self-hosted deployment shows as a CSP violation rather than a silent request.

Verified on 2026-09-19 with a `--base-href=/countscore/` build served by uvicorn under
`_PWA_CSP`, in Chromium at 412×860: fr-FR, zh-CN, ar and hi-IN from load to the home screen,
then a game created with the players "王小明 🎲" and "Zoé" — every request to the serving host
(Noto Sans SC slices, Noto Color Emoji, Noto Sans Arabic loaded from `fallback-fonts/`), no
CSP violation, text and emoji rendered. `flutter run -d chrome` (debug) is not covered: it
still uses the CDN defaults unless given `--no-web-resources-cdn`, and it is not published.

`build/web/flutter_service_worker.js` is still generated, and the loader keeps the stock
`serviceWorkerSettings`: this change did not touch the worker. A caching worker must not
precache `fallback-fonts/` (22 MB); cache those on first use.

> **Status: Outdated** (2026-09-19) — the PWA has its own worker now, and Flutter's is gone
> from the build and from the loader: see "Offline and updates".

### Offline and updates — `web/service_worker.js`

Flutter 3.47.2 ships no caching worker: its `flutter_service_worker.js` is a stub that
unregisters itself on activation, so before 2026-09-19 a reload with the network off failed
with `ERR_INTERNET_DISCONNECTED` while `manifest.json` said "works offline". CountScore has a
hand-written worker instead, and **exactly one**: a scope holds one registration, so the
stock loader registering Flutter's stub would replace ours. `web/flutter_bootstrap.js` passes
no `serviceWorkerSettings`, and `scripts/build_web.sh` deletes the stub from the build.

**Registration** — `web/flutter_bootstrap.js`, after `_flutter.loader.load`, on the `load`
event: `navigator.serviceWorker.register("service_worker.js", {updateViaCache: "none"})`.
Relative, so it resolves against the base href, and the default scope is the script's
directory: **`PWA_BASE_PATH` + `/`** on the backend's host, `/<repo>/` on Pages. No
`Service-Worker-Allowed` header is needed. The registration runs only when the line
`const countscoreServiceWorker = … // @service-worker` is `true`, which `build_web.sh` sets:
`flutter run -d chrome` and a bare `flutter build web` register nothing.

**What the build injects** — `build_web.sh`, last step, replaces three marked constants in
`build/web/service_worker.js`: `BUILD_ID`, the first 16 hex digits of a SHA-256 over every
other file's digest (the loader included, so any change makes a new id); `PRECACHE`, path →
SHA-256 of the shell (41 files, 10233 KB with Flutter 3.47.2: `index.html`, `main.dart.js`,
`flutter_bootstrap.js`, `flutter.js`, `sqlite3.wasm`, `drift_worker.js`, `manifest.json`,
`version.json`, icons, favicon and everything under `assets/` — Nunito, MaterialIcons,
`AssetManifest`, `FontManifest`, `NOTICES`, the rules, the shaders); and `ON_DEMAND`, the
`.js`/`.wasm` of every CanvasKit variant. Left out: `canvaskit/` (below), `fallback-fonts/`,
the `*.symbols`, `.last_build_id` and `sqlite3.wasm.sha256`.

**Caches** — `countscore-build-<BUILD_ID>` holds the shell and the CanvasKit variant the
browser uses; `countscore-fonts` holds the fallback fonts, shared by every build (their paths
are versioned, so a cached file is never stale).

- *Install* fetches each `PRECACHE` file with `cache: "no-cache"` (Pages sends `max-age=600`),
  hashes it and caches it only if the digest is the build's own — a mismatch means the server
  already holds another build, and the install fails so the browser retries with that
  build's worker. A file the previous build's cache holds with the same digest is copied, not
  downloaded, and a CanvasKit variant the previous build had cached is fetched too.
- *First visit*: the page loaded CanvasKit (one variant among several: `chromium/` in
  Chromium) and some fonts before the worker controlled it. Once it does (`clients.claim()`),
  the loader posts `performance.getEntriesByType("resource")` as a `cache-loaded` message and
  the worker caches the CanvasKit files (digest-checked) and fonts it names.
- *Fetch*: only `GET`s inside the scope. A navigation to the scope's root gets the cached
  `index.html` **with the headers it was served with**, `_PWA_CSP` included; a `PRECACHE` or
  `ON_DEMAND` path is cache-first; a font is cached when first fetched. Everything else — the
  API, a backend on another host, `privacy-policy.html` next to a Pages build — is not
  touched. A CanvasKit file missing from the cache whose network copy has another build's
  digest is refused (`Response.error()`) and the worker looks for its successor, which the
  loader then applies at once (the app never started).

**The update path** — a deploy replaces the build, so the next navigation (or the
`visibilitychange` check the loader adds, for an installed PWA left open) finds a
byte-different `service_worker.js` — the backend serves it `Cache-Control: no-cache`, and
`updateViaCache: "none"` bypasses the HTTP cache anyway. The new worker installs its whole
build beside the old one and **waits**; the open page keeps running on the old cache.
Then the loader, through `window.countscorePwa`:

1. if the app is on screen (`PwaUpdateListener` has set `onUpdateReady`,
   `lib/widgets/pwa_update_listener.dart`), shows the snackbar "A new version of CountScore is
   ready" — *Reload* (ARB `pwaUpdateReady`, `pwaUpdateReload`), which stays until acted on;
2. if not (the waiting worker is found while the page starts), applies it at once.

Applying posts `skip-waiting`; the new worker activates, deletes every other
`countscore-build-*` cache and claims the pages, and on `controllerchange` every page that had
a controller reloads — onto the new build, entirely from its cache. Closing every tab applies
it too, as for any worker. A page is therefore served by one build from start to finish.

Verified on 2026-09-19 with Playwright (Chromium 412×860) against uvicorn serving a
`--base-href=/countscore/` build under `_PWA_CSP`, the build folder swapped by rename as
`deploy_web.sh` does: after one online visit the registration's scope was
`http://localhost:8765/countscore/`, the build cache held 43 entries (41 + the `chromium/`
CanvasKit pair); offline, a reload opened the home screen and a game with two new players was
created and its board shown, with no failed request and no console error; in `zh-CN` the four
Noto Sans SC slices the home screen uses were cached and rendered offline. With build B
deployed under an open build-A page, `registration.update()` installed B beside A, the
snackbar appeared, *Reload* reloaded once, and every precached file the page received before
was A's digest and after was B's (`main.dart.js` differs between them), all from the worker;
A's cache was gone. `scripts/check_web_build.sh` refuses a build whose worker is unarmed,
that still carries Flutter's worker or `serviceWorkerSettings`, or whose files differ from the
worker's digests (`scripts/check_web_build_selftest.sh` pins each case).

What is not covered: a fallback font never fetched online is missing offline (the glyphs show
as boxes until the network returns); `countscore-fonts` is never pruned — an SDK upgrade
that re-versions the fonts leaves the old files in it
(`wip/todo_nr/2026-09-19-pwa-fonts-cache-never-pruned.md`); and no CI job runs the worker in a
browser (`wip/todo_nr/2026-09-19-pwa-service-worker-has-no-ci-browser-test.md`).

### GitHub Pages — `.github/workflows/deploy-pages.yml`

A second publishing path, beside the backend's own host ([[Deployment]]): on a push to `main`
touching `lib/`, `web/`, `assets/`, `pubspec.*`, `l10n.yaml`, the About icon, the privacy page,
`scripts/build_web.sh`, the two check scripts or the workflow itself — and on `workflow_dispatch` — it builds
with `scripts/build_web.sh --base-href=/<repo>/` (fallback fonts from the same cache as the
`app` job) and publishes to
`<owner>.github.io/<repo>/` through `actions/upload-pages-artifact` and `actions/deploy-pages`.
The base href is `github.event.repository.name`, never written in the file (a
`<owner>.github.io` repository gets `/`); a manual run from another branch builds but does not
deploy. No `BACKEND_URL`: the build is local-only until the visitor configures a server.

Before publishing it runs what `deploy_web.sh` runs — `scripts/web_binaries.sh --check`, then
`scripts/check_web_build.sh`, the one script both paths share (no `.md` outside
`assets/assets/`, `index.html`, `main.dart.js`, `sqlite3.wasm`, `drift_worker.js` present
and non-empty, and nothing fetched from Google — above). Its refusals are pinned against fixture builds by
`scripts/check_web_build_selftest.sh` in the `app` CI job, which also runs the check on its own
release web build ([[Testing]]).

**The site also carries the privacy policy.** A Pages site is one artifact per repository:
once the source is "GitHub Actions", `main:/docs` is no longer served, so the workflow copies
`docs/privacy-policy.html` to the site root — the URL the Play Console holds
([[Release]]) — refuses a build that already has a file by that name, and ends with a smoke
test of the page URL, the policy and the runtime files. `docs/README.md` is not published.

What differs from the same-origin deployment: no headers of ours (no `_PWA_CSP`, no
`Cache-Control: no-cache` — Pages caches about 10 minutes), no COEP either (as in production,
so Drift picks the same storage), and storage belongs to the Pages origin. The hash URL
strategy means a reload never asks Pages for a path it does not have.

### CORS and mixed content

The backend a user configures must whitelist the origin serving the PWA in its
`CORS_ORIGINS`, or the analysis call fails in the browser and nowhere else. A web build
served from `localhost` against a backend that does not list it cannot reach
`/comments/zapzap-analysis`; the e2e run skips that step for the same reason and it is
validated by `curl` and on a device instead — see [[Testing]].

A Pages build is in that position with every backend: its origin is
`https://<owner>.github.io` (scheme and host, no path — that is what `CORS_ORIGINS` compares),
and the operator must list it. The WebSocket is not subject to CORS, and the backend does not
check its `Origin`, so the sync *stream* would connect where the HTTP calls fail.

A second browser rule applies only on web: an `https://` page cannot call an `http://`
backend, whatever the app allows. `BackendProvider.check` accepts `http://` on a private
address for the Android case; on web that URL still only works from an http origin.

## Decisions & History

- **`sqlite3.wasm` and `drift_worker.js` are tracked in git on purpose** (`8a13541`),
  1.1 MB and all. `dart run drift_dev make-web-worker` does not compile at the pinned
  drift 2.34.4 / drift_dev 2.34.0 pairing, so the repository is the only reliable source
  for them. `.gitignore` carries a comment saying so. **Do not regenerate or delete them**
  until the CLI builds again — see `wip/done/ARCHIVE-2026-09.md`.

  > **Status: Outdated** (2026-09-09) — the stated reason does not hold. `make-web-worker`
  > is not a `drift_dev` subcommand in 2.34.6, and never needed to be: **drift ships a
  > prebuilt `drift_worker.js` at its package root**, so
  > `~/.pub-cache/hosted/pub.dev/drift-2.34.4/drift_worker.js` is an always-available source.
  > `sqlite3.wasm` comes from the `sqlite3.dart` GitHub releases, not from any package.
  > The two files remain tracked — a fresh clone should not have to fetch binaries to run
  > the PWA — but that is now a choice, not a workaround. **The committed
  > `drift_worker.js` is stale**: 351,222 B against the 355,222 B drift 2.34.4 ships.
  > Refreshing it is its own change, tracked in `wip/done/ARCHIVE-2026-09.md`.
- **The worker was refreshed from the drift 2.34.4 package (2026-09-13).** Byte-identical
  to `~/.pub-cache/hosted/pub.dev/drift-2.34.4/drift_worker.js`; validated by the web e2e
  and a manual launch under a sub-path. Whenever drift is bumped, copy the worker from the
  new version's package root in the same change. `sqlite3.wasm` was left alone: it embeds
  SQLite 3.53.1 and works with `sqlite3` 3.5.2.

  > **Status: Outdated** (2026-09-16) — both binaries moved on (drift 2.35.0, sqlite3
  > 3.6.0) and "copy it in the same change" is no longer something to remember:
  > `scripts/web_binaries.sh --refresh` does it, and `--check` runs in the `app` CI job.
- **A stale `web/` binary fails a required check now (2026-09-16).** Dependabot #43 (drift
  2.34.4 → 2.35.0) merged with five green checks and the 2.34.4 worker still committed:
  nothing compared the binaries to the lock, and the web e2e is not in CI. The check is a
  script rather than inline YAML so the same command is the local procedure, the CI gate and
  the refresh — `scripts/web_binaries.sh`, `wip/done/2026-09-14-dependabot-drift-worker.md`.
- **The wasm is checked by a committed digest, not by a download (2026-09-16).** `sqlite3`
  ships no `.wasm` in its package: it is a GitHub release asset. A CI step that fetched it
  on every run would be a network dependency on every pull request, and offline work would
  lose the check entirely. `web/sqlite3.wasm.sha256` makes the common case offline and
  hand-verifiable (`sha256sum -c web/sqlite3.wasm.sha256` from the repository root); the
  fetch is kept for the weekly `schedule:` run, where it catches a re-cut upstream release.
  The file lives in `web/` and not at the root so that `scripts/ci_scope.sh` classifies it
  as `app` alone rather than hitting the catch-all and running all five jobs on every
  refresh; it ships in `build/web/` as a consequence, 279 harmless bytes.
- **`web/CLAUDE.md` moved to `.claude/rules/web.md` (2026-09-13).** It was being shipped in
  every `build/web/`. A path-scoped rule loads when the same files are touched, and lives
  outside the tree Flutter copies. `scripts/deploy_web.sh` refuses any `.md` in the build
  so the class of leak cannot return through that path.
- **The Server section of Settings is *not* `kIsWeb`-guarded**, unlike export/import. The PWA needs a configured backend exactly as the Android app does, and a
  browser user has no other way to supply one.
- **Export/import is hidden rather than reimplemented on web.** It needs `dart:io`. Doing
  it properly means a `FileExporter` abstraction with a JSON serialisation path for the
  browser; that was scoped out of v1 rather than shipped half-working.
- **`index.html` was left stock.** Every customisation is one more thing to reconcile on a
  Flutter upgrade, and none was needed to ship.
- **The PWA is also published on GitHub Pages (2026-09-19).** The repository is public and
  the build fully static, and a Pages build with no server fits "no default backend URL": it
  gives the app to anyone without a self-hosted backend. The checks were moved out of
  `deploy_web.sh` into `scripts/check_web_build.sh` so the two paths run the same code rather
  than two copies. No real Pages URL is written in the repository (refinement 6): the wiki and
  `README.md` say `<owner>.github.io/<repo>/`, as for any deployment host.
- **GitHub's hosting logs are not a new outbound data flow (2026-09-19).** Loading the PWA from
  Pages sends GitHub the request for the app's own static files — the address and user agent
  any web host sees, as it already does for the privacy page and the repository. No game data,
  no setting and no identifier goes to GitHub, and the build fetches nothing the self-hosted
  one does not (CanvasKit and fallback fonts from Google's `gstatic.com`, [[Security]] — that
  pre-existing web-only flow is undisclosed, `wip/todo_nr/2026-09-19-pwa-gstatic-undisclosed.md`).

  > **Status: Outdated** (2026-09-19) — neither build fetches anything from Google now: see
  > "Self-hosted web resources" and the decision below.
  It is the distribution channel, like the Play Store download, not a call the app makes, so `README.md` Privacy, `privacy_policy.md` and
  `PLAY_STORE_DATA_SAFETY.md` (which covers the Android binary alone) are unchanged
  ([[Documentation]]).
- **Keep screen awake came back to the PWA (2026-09-19).** It had been hidden behind
  `kIsWeb` on the assumption that wakelock_plus did nothing in a browser, while its heading
  stayed drawn — so Settings ended on a bare "Screen" heading and read as a page cut short.
  The plugin has a real web path that the CSP allows, and a phone on a games table is
  exactly where the screen should stay on, so the guard went rather than the heading.
  `wip/done/2026-09-19-settings-screen-section-is-empty-on-the-web.md`.
- **The web database is made durable by an interceptor, not by a storage change or an
  upgrade (2026-09-19).** drift 2.35.0 and sqlite3 3.6.0 were the latest releases, so there
  was nothing to upgrade to. Forcing OPFS needs `SharedArrayBuffer`, hence COOP/COEP headers,
  which GitHub Pages cannot send and which would constrain every self-hosted deployment. An
  extra flush on the `unload` event cannot be awaited. A `QueryInterceptor` in
  `connection_web.dart` costs one `SELECT 1` per transaction and makes every returned call
  durable. `wip/done/2026-09-19-pwa-reload-reruns-the-database-creation.md`.
- **Self-host CanvasKit and the fallback fonts rather than disclose them (2026-09-19,
  refinement 6).** The README said "no font is fetched at runtime" and "by default nothing
  leaves the device", and every PWA visitor's browser was calling `gstatic.com`. Making the
  claim true beat adding a sentence to three privacy documents. For the fonts, mirroring the
  engine's own fallback set was chosen over bundling one fallback font in `pubspec.yaml`:
  the ten languages need CJK (about 920 distinct ideographs in the ARB and rules files
  alone, and any a player types), Arabic and Devanagari, plus emoji in names. A bundled font
  covering that is several MB of TTF that the engine downloads eagerly on every start, that
  the APK would carry for nothing (Android falls back to system fonts), and that a subset
  would still miss for user-typed names. The mirror keeps today's rendering and lazy loading
  unchanged, costs 22 MB on the server and a one-time download on the build machine, and
  needs no glyph list maintained by hand. `wip/done/2026-09-19-pwa-gstatic-undisclosed.md`.
- **A hand-written service worker, not Flutter's (2026-09-19, refinement 7).** Flutter's
  offline-first worker is deprecated and now a self-unregistering stub, and the manifest
  promised "works offline" while nothing cached anything; the refinement chose to make the
  claim true. Workbox or another generator would be a build dependency outside the Flutter
  toolchain for ~200 lines of worker. The cache is named after a build id computed by
  `build_web.sh` (not Flutter's random `serviceWorkerVersion`, which changes on every build and
  would prompt users for identical code), and every cached file is digest-checked, so neither
  a deploy mid-install nor an HTTP cache can put two builds in one cache. The update waits for
  the user rather than `skipWaiting()` on install: a page already running must not start
  loading another build's files, and the prompt costs one tap. The fallback fonts stay out of
  the precache (22 MB for the few slices one language needs), and only the CanvasKit variant
  a browser really loads is cached (5.4 MB of the 12.7 MB the two usual variants weigh).
  `wip/done/2026-09-19-pwa-has-no-offline-service-worker.md`.
- **The PWA shell lost its template metadata (2026-09-19).** `theme_color` `#673AB7` (the
  deep purple of an earlier theme) became the brand teal `#0E8F88`, mirrored by a
  `theme-color` meta; "A new Flutter project." became a description; the title is
  "CountScore". The manifest keeps "works offline", which the planned service worker will
  make true. `wip/done/2026-09-19-pwa-shell-still-says-flutter-template-and-offline.md`.
