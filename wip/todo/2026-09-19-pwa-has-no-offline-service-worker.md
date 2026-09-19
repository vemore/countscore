# The PWA has no offline service worker, so it does not open without a network

- **Noted:** 2026-09-19 — refinement 6, deciding [[2026-09-19-pwa-shell-still-says-flutter-template-and-offline]]
- **Theme:** web
- **Area:** web
- **Blocks release:** no

On the production PWA, `navigator.serviceWorker.getRegistrations()` is empty and a reload with
the network off fails with `ERR_INTERNET_DISCONNECTED`: Flutter web no longer ships an
offline-caching worker by default. Yet `web/manifest.json` promises "works offline", and the
app itself needs no network (the data lives in the browser, the backend is optional). The
2026-09-19 refinement decided to make the claim true rather than drop it.

**Fix:** a small hand-written service worker in `web/` that precaches the build's shell
(`index.html`, `main.dart.js`, `flutter_bootstrap.js`, CanvasKit, `sqlite3.wasm`,
`drift_worker.js`, fonts, assets) and serves it cache-first, with the cache named after the
build so a deploy replaces it; the app offers a reload when a new worker is waiting. Needs
[[2026-09-19-pwa-gstatic-undisclosed]] first: CanvasKit must be served by the PWA itself.
Check the worker against `_PWA_CSP` (`worker-src`), the `PWA_BASE_PATH` scope, and
`.claude/rules/web.md`; document the update path in `.llmwiki/` (web page) and `web-deploy`.

**Acceptance:**
- After one online visit, the PWA opens and creates a game with the network off (web e2e or a Playwright check attached to the pull request).
- After a deploy, an open PWA picks up the new build within one reload after the prompt, and never mixes files from two builds.
- `_PWA_CSP` still has no wildcard, and the worker's scope is the `PWA_BASE_PATH`.

**Promoted (2026-09-19, refinement 7):** promoted together with
[[2026-09-19-pwa-gstatic-undisclosed]]; `ship-parallel` starts it only once that one is merged.
