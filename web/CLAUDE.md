# CountScore Web (PWA) — Instructions for Claude Code

This directory holds the Flutter web scaffold: `index.html`, `manifest.json`, icons, and
the two Drift runtime binaries. The PWA's Dart code lives in `lib/` like every other
target — there is no separate web source tree.

## Read the wiki first

- `.llmwiki/Web.md` — persistence, feature guards, build, the CORS caveat
- `.llmwiki/DataLayer.md` — why web takes a different database path from native
- `.llmwiki/Testing.md` — the chromedriver e2e recipe

## Rules

1. **`sqlite3.wasm` (744 KB) and `drift_worker.js` (351 KB) are tracked in git on purpose**,
   so a fresh clone can run the PWA without fetching binaries. `drift_worker.js` also ships
   prebuilt at the drift package root (`~/.pub-cache/hosted/pub.dev/drift-<version>/`);
   `sqlite3.wasm` comes from the `sqlite3.dart` GitHub releases. There is no
   `drift_dev make-web-worker` subcommand — do not go looking for one. **Do not delete or
   gitignore these two files**; `.gitignore` carries a comment saying so. The committed
   worker is currently one build behind drift 2.34.4 — refreshing it is tracked in `TODO.md`.
2. **`connection_web.dart` must keep passing `DriftWebOptions` explicitly.** Without the
   explicit `sqlite3Wasm` and `driftWorker` URIs, drift_flutter 0.3.0 throws `ArgumentError`
   at startup and the PWA crashes — while the build still passes clean. If the web app dies
   on launch with a green build, look there first.
3. **`--no-tree-shake-icons` applies to web too.** Game-type icons come from the database.
4. **Guard platform features with `kIsWeb`.** Export/import and wakelock are unavailable —
   see `settings_provider.dart` and `settings_screen.dart`. Do not remove those guards
   without implementing a real web path.
5. **`index.html` is the stock Flutter template.** Keep it that way unless there is a
   concrete need; every customisation is one more thing to reconcile on an SDK upgrade.

## Commands

```bash
# Run locally
flutter run -d chrome
# --dart-define=BACKEND_URL=<url> is optional: it only seeds the runtime setting
# on a profile that has never configured a server. Leave it out and configure the
# server in Settings, like a user would.

# Build
flutter build web --release --no-tree-shake-icons
# add --base-href=/subpath/ if not served from the domain root

# End-to-end (chromedriver major version must match installed Chrome)
chromedriver --port=4444 &
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d web-server --browser-name=chrome --headless \
  --dart-define=BACKEND_URL=<your backend URL>
```

## Gotchas

- **CORS is the backend operator's problem, and it bites locally.** A backend whose
  `CORS_ORIGINS` does not list the origin serving the web build cannot be reached from it,
  so a locally served build usually cannot call `/comments/zapzap-analysis`. The e2e run
  skips that step for the same reason; it is validated by `curl` and on a device instead.
- **A browser blocks `http://` from an `https://` page** whatever the app allows, so an
  `http://192.168.x.x` backend only works for a PWA that is itself served over http.
- **`pumpAndSettle` is insufficient in web tests.** The Drift web worker resolves
  asynchronously without scheduling a frame. Use the `_waitFor` / `_waitEnabled` /
  `_waitDashes` helpers in `integration_test/app_test.dart`; do not "simplify" them away.
- **There is no hosting configuration for the web app in this repo** — no vhost, no deploy
  script. `.llmwiki/Deployment.md` covers only the backend container.
