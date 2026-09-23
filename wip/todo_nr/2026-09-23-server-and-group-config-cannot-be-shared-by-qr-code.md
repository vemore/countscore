# The server and group configuration cannot be shared by QR code

- **Noted:** 2026-09-23 — user request
- **Theme:** groups-v2
- **Area:** app
- **Blocks release:** no

Bringing a new device into a group today means typing the server URL in Settings → Server,
then the invite code in Settings → Group (`lib/screens/settings_screen.dart`,
`lib/widgets/group_settings_section.dart`). The user wants Settings to show a QR code that
carries both, readable by any phone's QR reader.

The QR holds a plain HTTPS link on the user's own backend host (the PWA it already serves
under `PWA_BASE_PATH`), e.g. `https://<host><PWA_BASE_PATH>/join#s=<server>&g=<invite>`.
That page decides where to go:
- **Android, app installed** → open the app on a deep link that carries the configuration.
- **Android, app not installed** → the Play Store listing.
- **Anything else** → stay in the PWA.
Wherever it lands, a confirmation dialog offers to **replace** the current server and group
configuration, and shows the old and new values. Nothing changes silently.

Constraints the design must respect:
- **No default host** (`CLAUDE.md`): the app cannot declare verified App Links
  (`autoVerify`) for a host it doesn't know at build time. So Android is reached through
  an `intent://…#Intent;scheme=countscore;package=…;S.browser_fallback_url=<Play>;end`
  link from the landing page, plus a `countscore://` intent-filter in
  `AndroidManifest.xml` (none today; only MAIN/LAUNCHER).
- The invite code is a credential. It goes in the URL **fragment**, which is never sent to
  the server or its logs, and the PWA and the app both take it from there.
- The replace flow uses the existing join path (`GroupProvider`), so it inherits sync
  behaviour. Leaving a group that holds unsynced rows must warn first (see memory: sync
  bugs are the expensive ones).

**Fix:** a "Share configuration" QR sheet in Settings (a QR package, e.g. `qr_flutter`,
through the dependency review), a `/join` route in the PWA, a `countscore://join` handler
in the app (e.g. `app_links`), and a shared "replace configuration?" dialog. README and
`.llmwiki` pages for groups and deep links updated. No new outbound data flow: the QR is
rendered locally.

**Acceptance:**
- Settings shows a QR whose decoded payload round-trips (unit test: encode → parse → same server and invite).
- Opening `countscore://join#…` on Android shows the replace dialog; cancelling leaves the settings untouched (widget test + one device run).
- The PWA `/join#…` route shows the same dialog, and the fragment never reaches the backend (backend access log checked in the smoke test).
- The landing page on Android without the app sends the user to the Play listing (fallback URL checked in a test of the generated link).

**Open question:** should the QR also work for a server with no group (server URL only)?
And should the invite in the QR expire, which needs a backend change to invite codes?
