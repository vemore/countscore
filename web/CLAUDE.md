# CountScore Web (PWA) — Instructions for Claude Code

This directory holds the Flutter web scaffold: `index.html`, `manifest.json`, icons, and
the two Drift runtime binaries. The PWA's Dart code lives in `lib/` like every other
target — there is no separate web source tree.

## Read the wiki first

- `.llmwiki/Web.md` — persistence, feature guards, build, the CORS caveat
- `.llmwiki/DataLayer.md` — why web takes a different database path from native
- `.llmwiki/Testing.md` — the chromedriver e2e recipe

## Rules

1. **`sqlite3.wasm` (744 KB) and `drift_worker.js` (351 KB) are tracked in git on purpose.**
   `dart run drift_dev make-web-worker` does not compile at the pinned drift version, so
   this repository is the only reliable source for them. **Do not delete, regenerate, or
   gitignore them** until the CLI builds again — `.gitignore` carries a comment saying so,
   and `TODO.md` tracks the unblock.
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
flutter run -d chrome --dart-define=BACKEND_URL=https://countscore.ombivince.synology.me

# Build
flutter build web --release --no-tree-shake-icons \
  --dart-define=BACKEND_URL=https://countscore.ombivince.synology.me
# add --base-href=/subpath/ if not served from the domain root

# End-to-end (chromedriver major version must match installed Chrome)
chromedriver --port=4444 &
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d web-server --browser-name=chrome --headless \
  --dart-define=BACKEND_URL=https://countscore.ombivince.synology.me
```

## Gotchas

- **Production CORS does not allow a `localhost` origin**, so a locally served web build
  cannot reach `/comments/zapzap-analysis`. The e2e run skips that step for the same
  reason; it is validated by `curl` and on a device instead.
- **`pumpAndSettle` is insufficient in web tests.** The Drift web worker resolves
  asynchronously without scheduling a frame. Use the `_waitFor` / `_waitEnabled` /
  `_waitDashes` helpers in `integration_test/app_test.dart`; do not "simplify" them away.
- **There is no hosting configuration for the web app in this repo** — no vhost, no deploy
  script. `.llmwiki/Deployment.md` covers only the backend container.
