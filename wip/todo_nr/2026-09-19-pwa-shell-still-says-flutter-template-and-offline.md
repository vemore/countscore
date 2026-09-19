# The PWA shell still carries template metadata and promises an offline mode it does not have

- **Noted:** 2026-09-19 — full test pass of the production PWA (fresh Chromium profiles, Playwright, fr-FR at 412 × 860)
- **Theme:** web
- **Area:** web
- **Blocks release:** no

Seen on the production PWA (`/app/`):
- `web/manifest.json`: `theme_color` is `#673AB7`, the old deep purple, which colours the
  installed PWA's system bar. Its `description` says **"works offline"**.
- **No service worker is registered** (`navigator.serviceWorker.getRegistrations()` is
  empty), and reloading with the network off fails with `ERR_INTERNET_DISCONNECTED`. Flutter
  web builds no longer ship an offline-caching worker by default.
- `web/index.html:21` has `<meta name="description" content="A new Flutter project.">`, and
  `:32` has `<title>countscore</title>` in lower case.
- The two unlabelled icon buttons noted here moved to
  [[2026-09-19-app-bar-icon-buttons-have-no-label]] (2026-09-19, refinement).

**Fix:** teal `theme_color` and a matching `<meta name="theme-color">`, a real description,
and the title "CountScore". Either drop "works offline" from the manifest, or decide to ship
an offline shell (a separate decision, as it changes how updates reach users).

**Acceptance:**
- `web/manifest.json` has no `#673AB7` and no "offline" claim unless a worker ships;
  `web/index.html` has no "A new Flutter project".

**Open question:** ship an offline service worker, or drop the claim? (Asked again at the
2026-09-19 refinement; left for later. Decide together with
[[2026-09-19-pwa-gstatic-undisclosed]]: an offline shell needs CanvasKit self-hosted.)
