# The PWA has no `/join` route, so a QR scanned off Android lands nowhere

- **Noted:** 2026-09-24 — refinement, split out of [[2026-09-23-server-and-group-config-cannot-be-shared-by-qr-code]]
- **Theme:** groups-v2
- **Area:** web
- **Blocks release:** no

Part (c) of the QR configuration share. The QR holds
`https://<host><PWA_BASE_PATH>/join#s=<server>&g=<invite>`, served by the backend container
under `PWA_BASE_PATH`; the PWA has no such route today.

**Fix:** a `/join` route in the PWA that reads the fragment with part (a)'s parser and shows
its replace dialog; on Android it hands over to the app through part (b)'s `intent://` link.
The invite code stays in the fragment, which the browser never sends. Needs part (a) merged
first.

**Acceptance:**
- The PWA `/join#…` route shows the replace dialog (widget test on the route).
- The fragment never reaches the backend (backend access log checked in the post-deploy smoke test).
- A `/join` with no fragment or a malformed one opens the home screen with no dialog.
