# The PWA throws a bare uncaught `Error` on every load

- **Noted:** 2026-09-18 — while checking the board's wide layout on a release web build (feat/board-wide-layout)
- **Theme:** web
- **Area:** web
- **Blocks release:** no

`flutter build web --release --no-tree-shake-icons`, served by `python3 -m http.server` on
`127.0.0.1` and opened in Playwright's Chromium, logs one uncaught page error on every load,
about 30 ms after drift's `Using WasmStorageImplementation.sharedIndexedDb due to missing
browser features: {dedicatedWorkersInSharedWorkers, sharedArrayBuffers}` line. Playwright's
`pageerror` reports the message as just `Error`, with no stack. The app then works normally —
games open, rounds and scores are written and survive a reload — so the error is swallowed
somewhere, not fatal. It happens on the home screen, before any board is opened, so it is not
from the board change that surfaced it.

**Fix:** reproduce with a `--profile` or `--source-maps` build to get a stack; likely suspects
are the drift worker fallback, or a feature guard (`kIsWeb`) missing around a plugin at
startup (`.llmwiki/Web.md`). Either fix it, or catch it where it is thrown with a log line
that names it.

**Acceptance:** a release web build loads with no uncaught page error in Chromium.
