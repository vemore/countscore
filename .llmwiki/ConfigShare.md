# Config Share

> Scope: bringing a device onto the same server and group from a QR code — the link, its
> encoder and parser, the QR sheet, the shared "replace the configuration?" dialog.
> Related: [[Sync]] · [[Security]] · [[Deployment]] · [[Web]] · [[MobileApp]]
> Updated: 2026-09-26

## Facts

### The link — `lib/utils/config_link.dart`

`https://<host><PWA_BASE_PATH>/#/join?s=<server>&g=<share_token>`, built by
`encodeConfigLink(pwaBase, ConfigLink)`; without `g` for a device in no group. The route, the
server and the invite code all sit after `#`, which a browser never sends: the server sees
`GET <PWA_BASE_PATH>/` and nothing more, so the invite code — a credential ([[Security]]) —
stays out of its access log. Values are `Uri.encodeQueryComponent`-encoded.

`parseConfigLink` reads that shape and `countscore://join?s=…&g=…` (the hand-over to the
Android app, `encodeAppConfigLink`). On an `https://` link it takes `s` and `g` only from
after `#`, and ignores any in a query before it. It returns null for any other route or
scheme, a server `BackendProvider.check` refuses (which also canonicalises it), or an invite
code outside 1–128 printable ASCII characters; an empty `g` reads as no group.
`ConfigLink.toString` leaves the invite code out. Tests: `test/utils/config_link_test.dart`.

### The PWA base

The QR must open on any phone's camera, so it points at the PWA the user's own backend
serves, at `PWA_BASE_PATH` on its host ([[Deployment]]). **The app cannot learn that path**:
no endpoint reports it, and only the server's `.env` holds it. So the sheet asks for the *web
app address* once, validates it like a server URL (`BackendProvider.check`: `https://`, or
`http://` on a private network) and keeps it in SharedPreferences `pwaBaseUrl`
(`ConfigShareSheet.prefsKey`). In the PWA it starts from the app's own address,
`pwaBaseFromUri(Uri.base)` (the build's `--base-href`, minus any `index.html`, query or hash
route) — which is the GitHub Pages copy when that is the one running ([[Web]]).

### The sheet — `lib/widgets/config_share_sheet.dart`

*Share by QR code* in Settings → Server (`config_share_open`, enabled once a server is set) and
in Settings → Group while in a group (`group_share_qr`) opens `ConfigShareSheet`: the QR
(`ConfigQrCode`, key `config_share_qr`), a *Copy link* button, and the web app address field.
The QR is drawn on the device by a `CustomPainter` from the `qr` package's module matrix,
black on white in both themes with the standard 4-module quiet zone, medium error
correction. Nothing is sent to show it: no new outbound data flow. Tests:
`test/widgets/config_share_sheet_test.dart` (the QR's data parses back to the server and the
invite code, with and without a group).

### The replace dialog — `lib/widgets/replace_config_dialog.dart`

`showReplaceConfigDialog(context, ConfigLink)` is what a scanned link opens; it returns a
`ReplaceConfigResult`. It asks nothing when the device already has that server and that
group (`replaceConfigUnchanged`). Otherwise `ReplaceConfigDialog` shows the current and new
server and group (`ReplaceConfigPlan`: the new group is known only by its invite code), says
when the current group will be left, and asks for the nickname when a group is joined — the
same 64-code-point field as Settings → Group ([[Sync]], *The nickname*). *Cancel* changes
nothing.

On *Replace*, when a group is left while `GroupProvider.pendingChanges` is above 0, a second
question warns that those changes will never reach the group: leaving empties `outbox`
([[Sync]], *Joining*). Then, in this order: `GroupProvider.leave` (revoked on the old
server), `BackendProvider.setBaseUrl` and `GroupProvider.updateBackend` (the proxy provider
would only hand the URL over on its next rebuild), `GroupProvider.joinGroup`. A failed join
keeps the new server and shows the join error as a snackbar; Settings → Group can try again.
Settings follows a server replaced this way: its URL field listens to `BackendProvider`.
Tests: `test/widgets/replace_config_dialog_test.dart`, on `test/support/fake_group_provider.dart`.

### What opens a link

Nothing yet. The PWA's `#/join` route is `wip/todo/2026-09-24-the-pwa-has-no-join-route.md`,
the Android `countscore://join` filter `wip/todo/2026-09-24-the-app-opens-no-countscore-join-link.md`;
both call `parseConfigLink` and `showReplaceConfigDialog`.

## Decisions & History

- **Everything after `#` (2026-09-26, refinement).** The backend serves the PWA with
  `StaticFiles(html=True)` (`backend/app/main.py`) and Flutter web routes by hash, so a
  `<base>/join` path would 404, and a query before `#` would put the invite code in the
  server's log. `wip/done/2026-09-23-server-and-group-config-cannot-be-shared-by-qr-code.md`.
- **The QR asks for the PWA's address rather than guessing it (2026-09-26).** Deriving it
  from the server URL would mean inventing a path — a default, which `CLAUDE.md` rules out —
  and having the backend report `PWA_BASE_PATH` would be a backend change the entry ruled
  out. Asked once and kept, with the PWA's own address as the exact starting value there.
  Rejected too: a `countscore://` QR, which only the installed Android app could open.
- **`qr`, not `qr_flutter` (2026-09-26).** `qr_flutter` 4.1.0 is from 2023-05 and pins
  `qr` ^3; `qr` itself (BSD-3-Clause, kevmoo.com, 4.0.0 of 2026-05, pure Dart, one dependency:
  `meta`) is maintained, and painting its module matrix takes one `CustomPainter`.
- **The replace dialog leaves, then switches server, then joins (2026-09-26).** Leaving first
  revokes the device on the server it registered with; joining goes through `joinGroup`, so it
  inherits the sync bookkeeping. `leave` empties the outbox, so a group with unsynced changes
  is only left after a second, explicit question.
