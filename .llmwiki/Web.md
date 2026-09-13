# Web

> Scope: everything specific to the PWA build.
> Related: [[DataLayer]] · [[MobileApp]] · [[Testing]] · [[LlmProviders]] · [[KnownLimits]]
> Updated: 2026-09-13

## Facts

### What is in `web/`

`index.html` (1525 B, **stock Flutter template, zero customisation** — `$FLUTTER_BASE_HREF`,
`flutter_bootstrap.js async`, no custom loader or service-worker code) · `manifest.json`
(CountScore, standalone, portrait-primary, theme `#673AB7`) · `favicon.png` · `icons/`
(4 PNGs) · and the two Drift runtime binaries: **`sqlite3.wasm` (744 KB)** and
**`drift_worker.js` (355 KB, the prebuilt worker from drift 2.34.4)**.

Nothing else belongs in `web/`: Flutter copies the whole directory into `build/web/`, so
any file placed there is published. The Claude Code instructions for the PWA live in
`.claude/rules/web.md` for that reason.

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

### Feature guards

`kIsWeb` appears in only two files, plus the conditional export in `connection.dart`:

- `lib/providers/settings_provider.dart:13,35,45,59` — export/import throw
  `UnsupportedError`; wakelock is a silent no-op.
- `lib/screens/settings_screen.dart:73,86,89,211` — hides the wakelock and export/import
  UI blocks entirely.

### Building

```bash
flutter build web --release --no-tree-shake-icons
```

`--dart-define=BACKEND_URL=<url>` is optional and seeds the runtime setting only on a
profile that has never configured a server — see [[LlmProviders]]. CI passes no such flag.

`--no-tree-shake-icons` applies to web exactly as it does to apk — see [[MobileApp]].
Add `--base-href=/subpath/` if not served from the domain root.

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
  until the CLI builds again — see `TODO.md`.

  > **Status: Outdated** (2026-09-09) — the stated reason does not hold. `make-web-worker`
  > is not a `drift_dev` subcommand in 2.34.6, and never needed to be: **drift ships a
  > prebuilt `drift_worker.js` at its package root**, so
  > `~/.pub-cache/hosted/pub.dev/drift-2.34.4/drift_worker.js` is an always-available source.
  > `sqlite3.wasm` comes from the `sqlite3.dart` GitHub releases, not from any package.
  > The two files remain tracked — a fresh clone should not have to fetch binaries to run
  > the PWA — but that is now a choice, not a workaround. **The committed
  > `drift_worker.js` is stale**: 351,222 B against the 355,222 B drift 2.34.4 ships.
  > Refreshing it is its own change, tracked in `TODO.md`.
- **The worker was refreshed from the drift 2.34.4 package (2026-09-13).** Byte-identical
  to `~/.pub-cache/hosted/pub.dev/drift-2.34.4/drift_worker.js`; validated by the web e2e
  and a manual launch under a sub-path. Whenever drift is bumped, copy the worker from the
  new version's package root in the same change. `sqlite3.wasm` was left alone: it embeds
  SQLite 3.53.1 and works with `sqlite3` 3.5.2.
- **`web/CLAUDE.md` moved to `.claude/rules/web.md` (2026-09-13).** It was being shipped in
  every `build/web/`. A path-scoped rule loads when the same files are touched, and lives
  outside the tree Flutter copies. `scripts/deploy_web.sh` refuses any `.md` in the build
  so the class of leak cannot return through that path.
- **The Server section of Settings is *not* `kIsWeb`-guarded**, unlike wakelock and
  export/import. The PWA needs a configured backend exactly as the Android app does, and a
  browser user has no other way to supply one.
- **Export/import is hidden rather than reimplemented on web.** It needs `dart:io`. Doing
  it properly means a `FileExporter` abstraction with a JSON serialisation path for the
  browser; that was scoped out of v1 rather than shipped half-working.
- **`index.html` was left stock.** Every customisation is one more thing to reconcile on a
  Flutter upgrade, and none was needed to ship.
