# The server and group configuration cannot be shared by QR code

**Status:** done (2026-09-26) — closed by feat/config-share-qr. Settings → Server and Settings → Group show a QR of `<web app address>/#/join?s=…&g=…` (`lib/widgets/config_share_sheet.dart`, `qr` package, drawn locally), built and read by `lib/utils/config_link.dart` (both link shapes), and `showReplaceConfigDialog` (`lib/widgets/replace_config_dialog.dart`) replaces server and group through `GroupProvider`, warning before a group with unsynced changes is left. The app cannot learn `PWA_BASE_PATH`, so the sheet asks for the web app address once (the PWA's own address in the PWA): `.llmwiki/ConfigShare.md`.

- **Noted:** 2026-09-23 — user request
- **Theme:** groups-v2
- **Area:** app
- **Blocks release:** no

Bringing a new device into a group today means typing the server URL in Settings → Server,
then the invite code in Settings → Group (`lib/screens/settings_screen.dart`,
`lib/widgets/group_settings_section.dart`). The user wants Settings to show a QR code that
carries both, readable by any phone's QR reader.

The QR holds a plain HTTPS link on the user's own backend host (the PWA it already serves
under `PWA_BASE_PATH`), e.g. `https://<host><PWA_BASE_PATH>/#/join?s=<server>&g=<invite>`.
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

**Decided (2026-09-24, refinement):** split in three, this entry keeping part (a); the others
are [[2026-09-24-the-app-opens-no-countscore-join-link]] and
[[2026-09-24-the-pwa-has-no-join-route]], which build on it. The QR also works for a server
with no group: it then carries the server alone. The invite code does not expire: the current
code goes in as it is, no backend change.

**Decided (2026-09-26, refinement):** everything goes in the fragment. The backend serves the
PWA with `StaticFiles(html=True)` (`backend/app/main.py:77`) and Flutter web routes by hash, so
a `<base>/join#…` path would 404. The link is `https://<host><PWA_BASE_PATH>/#/join?s=<server>&g=<invite>`:
the path the server sees is the PWA root, and the route, the server and the invite all sit
after `#`, which the browser never sends. No backend change. All three entries are promoted;
`ship-parallel` delivers this one (a) first, then (b) and (c) together in one pull request (same
parser, same dialog).

**Fix (part a):** a "Share configuration" QR sheet in Settings (a QR package, e.g.
`qr_flutter`, through the dependency review), the link's encoder and parser in one Dart
file, and the shared "replace configuration?" dialog, which joins through `GroupProvider` and
warns before leaving a group that holds unsynced rows. No new outbound data flow: the QR is
rendered locally.

**Acceptance:**
- Settings shows a QR whose decoded payload round-trips (unit test: encode → parse → same server and invite), with and without a group.
- The link has the form `<base>/#/join?s=…&g=…`: the server and the invite code are only after `#`, never in the path or in a query before `#` (unit test on the encoder).
- The replace dialog shows the old and new values; cancelling leaves the settings untouched (widget test).
- Leaving a group with unsynced rows through the dialog warns first (widget test with a fake `GroupProvider`).
