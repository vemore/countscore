# The PWA fetches CanvasKit and fonts from Google, and no privacy document says so

- **Noted:** 2026-09-19 — deciding whether the GitHub Pages build is a new data flow (ci/pwa-github-pages)
- **Theme:** web
- **Area:** web
- **Blocks release:** no — the Play Store declaration covers the Android binary, which fetches neither

A Flutter web release build loads CanvasKit from `www.gstatic.com/flutter-canvaskit/`
(`build/web/flutter_bootstrap.js`) and, when a glyph is missing from the bundled Nunito, fallback
fonts from `fonts.gstatic.com`. The backend's `_PWA_CSP` allows both on purpose
(`backend/app/main.py:28-39`, [[Security]]). So every PWA visitor's browser makes requests to
Google — address and user agent, no app data — whether the PWA is served by a self-hosted
backend or by GitHub Pages.

Nothing discloses it: `README.md` Privacy says "by default nothing leaves the device at all",
its Features section says "no font is fetched at runtime" (`README.md:74`), and
`privacy_policy.md` names no Google request for the web version.

**Fix:** either say it — one sentence in `README.md` Privacy and `privacy_policy.md` (web
version only; regenerate `docs/privacy-policy.html`), `PLAY_STORE_DATA_SAFETY.md` unchanged —
or stop it: build with `--no-web-resources-cdn` (CanvasKit served from the build itself) and
bundle a fallback font, then drop `www.gstatic.com` and `fonts.gstatic.com` from `_PWA_CSP`.

**Acceptance:**
- A PWA session, from load to a game created, makes no request to a Google host.
- `_PWA_CSP` names no `gstatic.com` host.
- `README.md:81` ("no font is fetched at runtime") is true on every platform it covers.

**Decided (2026-09-19, refinement 6):** self-host. Build with `--no-web-resources-cdn`
(in `web-deploy` and the CI web build), bundle a fallback font, and drop `www.gstatic.com` and
`fonts.gstatic.com` from `_PWA_CSP` and [[Security]]. No privacy document changes, since the
claim becomes true. Lands before [[2026-09-19-pwa-has-no-offline-service-worker]].
