# The app opens no `countscore://join` link, so a scanned QR cannot reach it

**Status:** done (2026-09-26) — closed by feat/config-share-join-link. `MainActivity` declares a `countscore://join` VIEW/BROWSABLE filter (custom scheme, no `autoVerify`), `app_links` delivers the link to `JoinLinkInbox`, and `JoinLinkListener` opens `showReplaceConfigDialog` once `GroupProvider.loaded`; the PWA's hand-over is `encodeAndroidIntentLink`. Covered by `test/widgets/join_link_listener_test.dart` and `test/utils/config_link_test.dart`; the one device run is deferred to a local session.

- **Noted:** 2026-09-24 — refinement, split out of [[2026-09-23-server-and-group-config-cannot-be-shared-by-qr-code]]
- **Theme:** groups-v2
- **Area:** app, android, web
- **Blocks release:** no

Part (b) of the QR configuration share. `android/app/src/main/AndroidManifest.xml` declares
only the MAIN/LAUNCHER and `mailto` intent filters: no scheme of the app's own. Verified App
Links (`autoVerify`) are out, since the app knows no host at build time (`CLAUDE.md`: no
default host).

**Decided (2026-09-26, refinement):** the QR link is `https://<host><PWA_BASE_PATH>/#/join?s=<server>&g=<invite>`
(everything after `#`, see part (a)). In an Android `intent://` URI the `#` is taken by
`#Intent;…;end`, so the earlier `intent://join#…#Intent…` form is invalid: the hand-over
carries the payload as a query, `intent://join?s=…&g=…#Intent;…;end`, which opens
`countscore://join?s=…&g=…`. That link goes from the browser to the app on the device and
never reaches the server. Part (a)'s parser reads both shapes (`#/join?…` and
`countscore://join?…`). Delivered with (c), in one pull request, once (a) is merged.

**Fix:** a `countscore://join` intent filter and a handler (e.g. `app_links`, through the
dependency review) that parses the link with part (a)'s parser and opens its replace
dialog. The PWA's `#/join` route sends an Android browser to
`intent://join?s=<server>&g=<invite>#Intent;scheme=countscore;package=com.vemore.countscore;S.browser_fallback_url=<Play listing>;end`.
Needs part (a) merged first.

**Acceptance:**
- Opening `countscore://join?s=…&g=…` on Android shows the replace dialog; cancelling leaves the settings untouched (widget test + one device run).
- The generated `intent://` link carries the payload as a query before `#Intent` and the Play listing as `browser_fallback_url` (unit test).
- `.llmwiki/` documents the deep link, and README says how a device joins by QR.
