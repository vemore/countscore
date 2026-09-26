# The PWA on Android offers "Open in the app" for a link that changes nothing

- **Noted:** 2026-09-26 — independent review of #237 (finding 4), from the local session that merged it
- **Theme:** groups-v2
- **Area:** web
- **Blocks release:** no

In `lib/widgets/join_link_listener.dart` (`_open`), the PWA running in an Android browser
asks *Open in the app / Continue in the browser* before anything checks whether the link
changes the configuration. A PWA user who scans their own group's QR and taps *Open in the
app* leaves for the app, or for the Play listing when it is not installed, although the
replace dialog would only have said the device already uses this configuration.

**Fix:** build the replace plan first (the one `showReplaceConfigDialog` computes) and skip
the hand-over question when the plan changes nothing; show the "already uses this
configuration" answer in place.

**Acceptance:**
- In a widget test with `offerAppHandOver: true`, a link equal to the current server and group shows no hand-over dialog.
- A link that changes the server or the group still asks the hand-over question first.
