# The PWA has no `/join` route, so a QR scanned off Android lands nowhere

- **Noted:** 2026-09-24 — refinement, split out of [[2026-09-23-server-and-group-config-cannot-be-shared-by-qr-code]]
- **Theme:** groups-v2
- **Area:** web
- **Blocks release:** no

Part (c) of the QR configuration share. The QR holds
`https://<host><PWA_BASE_PATH>/#/join?s=<server>&g=<invite>`, served by the backend container
under `PWA_BASE_PATH`; the PWA has no such route today.

**Decided (2026-09-26, refinement):** the route is the hash route `#/join`, not a `/join`
path. The backend serves the PWA with `StaticFiles(html=True)` (`backend/app/main.py:77`), which
would 404 a `<base>/join` path, and Flutter web routes by hash: with `#/join?…` the server sees
only the PWA root, and no backend or `StaticFiles` change is needed. Delivered with (b), in one
pull request, once (a) is merged.

**Fix:** a `#/join` route in the PWA that reads its query with part (a)'s parser and shows
its replace dialog; on Android it hands over to the app through part (b)'s `intent://` link.
The route, the server and the invite code stay after `#`, which the browser never sends.
Needs part (a) merged first.

**Acceptance:**
- The PWA `#/join?s=…&g=…` route shows the replace dialog (widget test on the route).
- Nothing after `#` reaches the backend: the post-deploy smoke test finds only `GET <PWA_BASE_PATH>/` in the backend access log for a scanned link, with no `/join` and no invite code.
- A `#/join` with no query or a malformed one opens the home screen with no dialog.
