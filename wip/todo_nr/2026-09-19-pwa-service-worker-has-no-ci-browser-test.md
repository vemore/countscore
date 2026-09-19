# The PWA's service worker has no automated browser test

- **Noted:** 2026-09-19 — while writing feat/pwa-offline-service-worker
- **Theme:** web
- **Area:** web
- **Blocks release:** no

`web/service_worker.js` and the registration in `web/flutter_bootstrap.js` are about 300 lines
of JavaScript that nothing runs in CI. `scripts/check_web_build.sh` checks the build is armed
(build id, digests, no Flutter worker) and `test/widgets/pwa_update_listener_test.dart` covers
the Dart prompt with a fake, but offline start, the digest check and the update path were
verified once, by hand, with Playwright scripts that live outside the repository (the pull
request body has them; `.llmwiki/Web.md`, "Offline and updates"). An SDK upgrade that changes
how the loader fetches CanvasKit, or a refactor of the worker, would merge green.

**Fix:** a CI step (in the `app` job, after `scripts/check_web_build.sh`, or a job of its own
that `scripts/ci_scope.sh` selects for `web/` and `scripts/build_web.sh`) that serves the
built PWA under a sub-path — uvicorn with `PWA_BASE_PATH`, as `.llmwiki/Testing.md` describes —
and runs a Playwright script: one online visit, then offline reload and game creation; then a
second build swapped in by rename, the prompt, one reload, every precached response of the
new build's digest. Needs Node and a Playwright Chromium on the runner, and a second web build
(about 2 minutes) — weigh that against running it on `web/`-touching pull requests only.

**Acceptance:**
- A pull request that breaks offline start (e.g. empties `PRECACHE`) fails a check.
- A pull request that makes the worker serve a file of the previous build after the reload fails a check.
