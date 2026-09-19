# The PWA is only published behind a self-hosted backend, not on GitHub Pages

**Status:** done (2026-09-19) — closed by ci/pwa-github-pages. `.github/workflows/deploy-pages.yml`
builds with `--base-href=/<repo>/` from the repository name, runs `scripts/web_binaries.sh --check`
and `scripts/check_web_build.sh` (now shared with `deploy_web.sh`, self-tested in CI), and
publishes the PWA plus the privacy page, on a push to `main` touching the app and on
`workflow_dispatch`. Pages is currently the legacy `main:/docs` source; switching it to
*GitHub Actions*, running the workflow, and the two remaining acceptance items (the Pages URL
loads and keeps a game across a reload; CORS with a backend listing the Pages origin) are
verified by the orchestrator after merge. GitHub's hosting logs were judged not a new data
flow ([[Web]]).

- **Noted:** 2026-09-19 — asked whether the PWA can be deployed on GitHub Pages
- **Theme:** web
- **Area:** web
- **Blocks release:** no

Today the only way to get the PWA is the build the backend container serves under
`PWA_BASE_PATH` (`scripts/deploy_web.sh`, [[Deployment]]). Nothing prevents a static host:
`build/web/` is fully static, the drift URIs in
`lib/services/drift/connection/connection_web.dart` are relative and already checked under a
sub-path ([[Web]]), there is no path URL strategy (hash URLs, so a reload never 404s), and the
repository is public. A Pages build with no server configured runs local-only (scores,
stats), which fits "no default backend URL".

What changes against the same-origin deployment:
- **CORS**: the PWA becomes cross-origin to every backend; an operator must add the Pages
  origin to `CORS_ORIGINS` (`backend/app/config.py:46`), or analysis and sync fail in the
  browser only.
- **HTTPS backend only**: an `https://` page cannot call an `http://192.168.x.x` server.
- **No headers of our own**: no `_PWA_CSP`, no `Cache-Control: no-cache`
  (`backend/app/main.py:168-194`); Pages caches ~10 min. No COEP either — same as prod, so
  Drift picks the same storage.
- **Storage is per origin**: games in the NAS PWA do not follow, except through group sync.

**Fix:** `.github/workflows/deploy-pages.yml` — on push to `main` touching the app (and on
`workflow_dispatch`): build with `--release --no-tree-shake-icons --base-href=/<repo>/`,
run the checks `deploy_web.sh` does (no `.md` in the build, `scripts/web_binaries.sh`),
publish with `actions/upload-pages-artifact` + `actions/deploy-pages`. Update [[Web]],
[[Deployment]], `README.md` (a CORS note for operators), and the privacy documents if
GitHub's hosting logs count as a new data flow ([[Documentation]]).

**Acceptance:**
- The workflow publishes on a push to `main` and a manual run; it fails on a `.md` in
  `build/web/` or a stale `web/` binary.
- The Pages URL loads, creates a game, and keeps it across a reload.
- With a backend listing the Pages origin in `CORS_ORIGINS`, analysis and sync work from it.

**Decided (2026-09-19, refinement 6):** no real Pages URL in committed files. `README.md` and the
wiki describe `<owner>.github.io/<repo>/` only, as for any deployment host (`CLAUDE.md`).
