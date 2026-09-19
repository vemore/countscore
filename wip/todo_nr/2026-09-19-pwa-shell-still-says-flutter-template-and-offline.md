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
- Also: an icon button with no semantic label on home (statistics) and on the board
  (results), so a screen reader announces a bare "button".

**Fix:** teal `theme_color` and a matching `<meta name="theme-color">`, a real description,
and the title "CountScore". Either drop "works offline" from the manifest, or decide to ship
an offline shell (a separate decision, as it changes how updates reach users). Add tooltips
to the two icon buttons.

**Acceptance:**
- `web/manifest.json` has no `#673AB7` and no "offline" claim unless a worker ships;
  `web/index.html` has no "A new Flutter project".
- Every `IconButton` on home and the board has a `tooltip` (a widget test finds none
  without a semantic label).

**Open question:** ship an offline service worker, or drop the claim?
