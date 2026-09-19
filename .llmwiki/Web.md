# Web

> Scope: everything specific to the PWA build.
> Related: [[DataLayer]] · [[MobileApp]] · [[Testing]] · [[LlmProviders]] · [[KnownLimits]]
> Updated: 2026-09-19

## Facts

### What is in `web/`

`index.html` (1525 B, **stock Flutter template, zero customisation** — `$FLUTTER_BASE_HREF`,
`flutter_bootstrap.js async`, no custom loader or service-worker code) · `manifest.json`
(CountScore, standalone, portrait-primary, theme `#673AB7`) · `favicon.png` · `icons/`
(4 PNGs) · the two Drift runtime binaries: **`sqlite3.wasm` (748686 B, sqlite3 3.6.0)** and
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
)
```

SQLite compiled to wasm, persisted through OPFS (IndexedDB fallback) by `drift_flutter`.

**Those explicit URIs are load-bearing.** Without them, drift_flutter 0.3.0 throws
`ArgumentError` at startup and the PWA crashes — while the *build* still passes clean. If
the web app dies on launch with nothing wrong at compile time, look here first.

There is no legacy database on web, so `bootstrapMigrate()` never runs: Drift's `onCreate`
builds schema v9 directly. See [[DataLayer]].

> **Status: Outdated** (2026-09-13) — `onCreate` builds the current schema (v11), and a
> browser that already holds a database from an earlier PWA release upgrades through Drift's
> `onUpgrade`. See [[SchemaV10]].

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

**Keep screen awake works in the PWA.** wakelock_plus 1.8.0's web plugin injects
`assets/packages/wakelock_plus/assets/no_sleep.js` as a same-origin `<script>` (allowed by
`script-src 'self'`) and calls `navigator.wakeLock.request('screen')`, which no CSP
directive governs; it re-requests the lock on `visibilitychange`, since a browser drops it
when the tab is hidden. The API needs a secure context (https, or `localhost`). A browser
without `navigator.wakeLock` gets NoSleep's fallback — a looping `data:` video — which the
PWA's `default-src 'self'` blocks as media, so there the switch is saved but holds nothing;
the failure lands in the provider's `catch`. Verified on 2026-09-19 in Chromium at 412×860
under `_PWA_CSP` (`backend/app/main.py:34`): the switch obtains a `WakeLockSentinel`
(`type: screen`), turning it off releases it, the setting is re-applied after a reload, and
no CSP violation is logged. The lock is applied when `SettingsProvider` is first read — it
is a lazy provider (`lib/main.dart:53`) — as on Android.

### Building

```bash
flutter build web --release --no-tree-shake-icons
```

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

### CORS and mixed content

The backend a user configures must whitelist the origin serving the PWA in its
`CORS_ORIGINS`, or the analysis call fails in the browser and nowhere else. A web build
served from `localhost` against a backend that does not list it cannot reach
`/comments/zapzap-analysis`; the e2e run skips that step for the same reason and it is
validated by `curl` and on a device instead — see [[Testing]].

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
- **Keep screen awake came back to the PWA (2026-09-19).** It had been hidden behind
  `kIsWeb` on the assumption that wakelock_plus did nothing in a browser, while its heading
  stayed drawn — so Settings ended on a bare "Screen" heading and read as a page cut short.
  The plugin has a real web path that the CSP allows, and a phone on a games table is
  exactly where the screen should stay on, so the guard went rather than the heading.
  `wip/done/2026-09-19-settings-screen-section-is-empty-on-the-web.md`.
