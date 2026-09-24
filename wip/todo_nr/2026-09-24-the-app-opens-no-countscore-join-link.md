# The app opens no `countscore://join` link, so a scanned QR cannot reach it

- **Noted:** 2026-09-24 — refinement, split out of [[2026-09-23-server-and-group-config-cannot-be-shared-by-qr-code]]
- **Theme:** groups-v2
- **Area:** app, android, web
- **Blocks release:** no

Part (b) of the QR configuration share. `android/app/src/main/AndroidManifest.xml` declares
only the MAIN/LAUNCHER and `mailto` intent filters: no scheme of the app's own. Verified App
Links (`autoVerify`) are out, since the app knows no host at build time (`CLAUDE.md`: no
default host).

**Fix:** a `countscore://join` intent filter and a handler (e.g. `app_links`, through the
dependency review) that parses the fragment with part (a)'s parser and opens its replace
dialog. The PWA's landing page sends an Android browser to
`intent://join#…#Intent;scheme=countscore;package=com.vemore.countscore;S.browser_fallback_url=<Play listing>;end`.
Needs part (a) merged first.

**Acceptance:**
- Opening `countscore://join#…` on Android shows the replace dialog; cancelling leaves the settings untouched (widget test + one device run).
- The generated `intent://` link carries the Play listing as `browser_fallback_url` (unit test).
- `.llmwiki/` documents the deep link, and README says how a device joins by QR.
