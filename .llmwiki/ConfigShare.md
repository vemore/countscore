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
correction. It is encoded once per link, not per build (the sheet rebuilds on every keystroke
and sync status change); a link past a version-40 code's capacity shows `configShareTooLong`
instead. *Copy link* confirms on its own button (`configShareLinkCopied`): a snackbar would
land on the Settings page under the sheet. A stored address read late never overwrites one
the user has typed or saved meanwhile. Nothing is sent to show it: no new outbound data flow. Tests:
`test/widgets/config_share_sheet_test.dart` (the QR's data parses back to the server and the
invite code, with and without a group).

### The replace dialog — `lib/widgets/replace_config_dialog.dart`

`showReplaceConfigDialog(context, ConfigLink)` is what a scanned link opens; it returns a
`ReplaceConfigResult`. It asks nothing when the device already has that server and that
invite code (`replaceConfigUnchanged`). Otherwise `ReplaceConfigDialog` shows the current and
new server and group (`ReplaceConfigPlan`: the new group is known only by its invite code, and
a current group whose name is not known is shown by its own code, `currentGroupLabel`), says
the current group will be left when the server changes, and asks for the nickname when a group
is joined, with the Settings → Group field's limit (`groupFieldFormatter`, 64 code points;
[[Sync]], *The nickname*). *Cancel* changes nothing.

**A group is joined before anything is left.** On *Replace*, `GroupProvider.prepareJoin`
registers the device with the link's group on the link's server and changes nothing else; a
refusal (a replaced invite code, 429, no network) is shown as the join error and the current
server, group, credentials and outbox stay exactly as they were. Once the server has
accepted:

- **The same group** (its id is this device's group id, i.e. the same group behind a newer
  invite code) **and this device's own token still accepted**: `completeJoin` keeps the
  membership, withdraws the registration the join made (a self-revoke with its own token, which
  the server answers 204 without rotating the code), and stores the newer code. Nothing is left,
  no row unshared, no warning (`unchanged`, or `applied` when the URL it is reached by changed).
  "Still accepted" is asked of the server (`GET /groups/me` with the current token, 401/403 is
  a no) unless sync already reads `unauthorized`, and needs a token at all (`isJoined`): a
  device the owner revoked, or one whose secure storage was lost in a restore, is in the group
  by id only, so it takes the new registration through the path below.
- **Another group**: before the current one is left, a second question when the first did not
  already say so (same server) or when changes are waiting to reach it. The count is read then,
  from the outbox (`GroupProvider.countPending`), not from `pendingChanges`, which is only
  recounted at the end of a sync pass and reads 0 on a cold start from a link. *Cancel* there
  withdraws the new registration (`cancelJoin`). Then `completeJoin` leaves the current group
  (revoked on its own server, outbox emptied, [[Sync]] *Joining*), stores the new server URL
  (`BackendProvider.persist`, SharedPreferences `backendUrl`) before the new credentials, adopts
  the new membership and syncs with the new server; the dialog then tells the live
  `BackendProvider` (`setBaseUrl`).

**Killed half-way.** Between `prepareJoin` and `completeJoin` (the second question is open, or
the app dies): nothing changed on the device, and the new server keeps an unused device record
under the chosen nickname. It shows in that group's devices list, where the owner can revoke
it; and if the owner leaves, `_earliest_live_device` may hand it the owner role, which a live
member takes back with *Claim ownership* once it has been dormant. Inside `completeJoin`: the old
group is left first, then the URL, then the credentials reach the disk, so a restart finds
either no group on the old or new server (join again) or the new group on its own server; never
the new group's token under the old URL.

A link carrying a server alone, another one, leaves the group (a group cannot follow its
server) after the same question, then sets the server. Settings follows a server replaced
this way: its URL field listens to `BackendProvider`. `GroupProvider.createGroup` and
`joinGroup` from Settings follow the same rule: the server call first, then any current group
is left. Tests: `test/widgets/replace_config_dialog_test.dart` (on
`test/support/fake_group_provider.dart`, and once on the real provider),
`test/providers/group_provider_join_test.dart` (on `test/support/group_servers.dart`).

### What opens a link

Whatever the camera opens, the link lands in one `JoinLinkInbox`
(`lib/services/join_link_inbox.dart`), created in `main()` before anything else, and
`JoinLinkListener` (`lib/widgets/join_link_listener.dart`), wrapped around `HomeScreen` (the
route that stays at the bottom of the stack), opens each link it holds as
`showReplaceConfigDialog`, over whatever screen shows. Links are taken one at a time, each
after `GroupProvider.loaded` (the stored membership read by the provider's first
`updateBackend`): on a cold start the dialog would otherwise show no current group. A link
that does not parse (`parseReceivedConfigLink`: `parseConfigRoute` for a bare `/join?…`
route, `parseConfigLink` otherwise) opens nothing; the home screen stays. The inbox holds
links until the listener attaches and hands each delivery over once, so no rebuild or resume
of the running app replays one; an Android activity the system recreates after killing the
app is `MainActivity`'s to filter (below).

- **The PWA, `#/join?s=…&g=…`.** `takeJoinRouteFromLocation`
  (`lib/services/join_link_location_web.dart`) reads the hash before `runApp` and, when its
  path is `/join` (`isConfigLinkRoute`, well-formed or not), rewrites the current history
  entry to the PWA's root with `history.replaceState`: Flutter's history then starts on `/`,
  no entry keeps the invite code, and a reload or a back cannot open it again. A `#/join`
  reached while the PWA runs (the address edited, or an installed PWA navigated to a link
  that differs from its address by the hash) adds a history entry of its own, which
  Flutter's single-entry history records as its current route and steps back off
  (`go(-1)`), leaving it as a *forward* entry, then pushes the route. Three things handle it:
  `watchJoinRoutesInLocation`, a `popstate` listener registered before `runApp` (so ahead of
  Flutter's), rewrites that entry to a bare `#/join` and keeps the full route
  (`takeStrippedJoinRoute`), so neither Forward nor the tab's history holds the code; the
  inbox, a `WidgetsBindingObserver` registered before `runApp`, answers the push ahead of
  `WidgetsApp` (which would look for a named route and throw), taking the kept route for a
  bare `/join`, once; and it reports `/` to the engine (`SystemNavigator.routeInformationUpdated`,
  `replace: true`), which resets the single-entry history's route and entry, since that
  history re-creates its entry at its last route on a back to its origin, where a reload
  would open the link again. Engine code read: `SingleEntryBrowserHistory` in the Flutter
  web SDK's `engine/navigation/history.dart`. The browser's own list of visited pages
  still records the address as opened, as for any link.
- **An Android browser.** The PWA asks first (`joinLinkHandOverMessage`): *Open in the app*
  navigates to `encodeAndroidIntentLink` —
  `intent://join?s=…&g=…#Intent;scheme=countscore;package=com.vemore.countscore;S.browser_fallback_url=<Play listing>;end`,
  the payload a query before `#Intent` — which opens the app, or the Play listing
  (`kPlayStoreUrl`, which carries no payload) when it is not installed; *Continue in the
  browser* shows the replace dialog in the PWA. `offerAppHandOver` is
  `kIsWeb && defaultTargetPlatform == TargetPlatform.android`.
- **The Android app, `countscore://join?s=…&g=…`.** A `VIEW`/`BROWSABLE` intent filter on
  `MainActivity` for scheme `countscore`, host `join` — a custom scheme, no `https` host, no
  `autoVerify` — and `app_links` (`AppLinks().stringLinkStream`), which delivers the launch
  intent once, then each new intent (`launchMode="singleTop"`), and ignores a relaunch from
  the recents screen (`FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY`). That flag is *not* set when the
  activity is restored after process death — reopened from recents, it gets its original
  `VIEW` intent back (seen on the Pixel, 2026-09-26) — so `MainActivity.onCreate` drops the
  intent's data when `savedInstanceState` is non-null: a restored activity has already handled
  its link. Flutter's own deep linking is
  off (`flutter_deeplinking_enabled` false in the manifest): it would push the link as a
  Navigator route as well.

Nothing is fetched to open a link: the intent goes browser → app on the device, and the
dialog's first request is the join the user confirms. The merged manifest gains no
permission from `app_links` (its own manifest is empty). Tests:
`test/widgets/join_link_listener_test.dart`, `test/utils/config_link_test.dart`. The Android
path was run on the Pixel on 2026-09-26: cold, warm, and restored from recents after process
death. Not covered by any of them: the `popstate` listener and `history.replaceState`, which
only a browser runs.

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
- **Join first, leave only once the new group has accepted the device (2026-09-26).** The only
  order in which a failure loses nothing: until the server says yes, nothing on the device has
  changed. The cost is a registration to withdraw when the user then backs out at the unsynced
  warning, or when the group turns out to be this device's own: a self-revoke, which the server
  answers without rotating the code. The same group is recognised by its id in the join's
  answer, not by comparing invite codes, which a rotation changes; a group id is unique to its
  server, so the same id under another URL is the same group reached another way. The first
  draft of #236 left, then switched server, then joined; its review found that a join refused
  after the leave left the device revoked and in no group, its unsynced changes gone.
- **Same group means same id and a token that still works (2026-09-26).** Comparing ids alone
  kept a revoked device on its refused token and withdrew the fresh one the owner's QR had
  just given it: locked out, told "already uses this configuration". One authenticated
  `GET /groups/me` settles it. Swapping the new device id and token into the kept rows was
  the alternative; it was not taken because the sync state (lamport, last seq) belongs to the
  old device, and the plain leave-and-adopt path is already tested.
- **The server URL is stored by the join, not after it (2026-09-26).** `GroupProvider` writes
  it (`BackendProvider.persist`) between leaving and saving the new credentials, so no restart
  can pair the new group's token with the old URL. Storing the URL with the membership and
  reconciling on load was the alternative: more state, for the same guarantee.
- **`app_links`, not Flutter's own deep linking nor a channel of ours (2026-09-26,
  `feat/config-share-join-link`).** Flutter's deep linking (on by default since 3.27) turns
  `countscore://join?…` into the route `/?…` — the host lost, the query decoded — and pushes
  it into a Navigator that has no such route. A `MethodChannel` in `MainActivity` would have
  been some forty lines of Kotlin nobody can run outside a device. `app_links` 7.2.1:
  Apache-2.0, verified publisher cow-level.ovh, 160/160 pub points, published 2026-07; an
  empty Android manifest (no permission); it skips a relaunch from the recents screen, which
  a channel of ours would have had to learn — though not a restore after process death, which
  `MainActivity` handles (above). Its Linux half pulls `gtk` (MPL-2.0), which no
  Android or web build compiles.
- **The PWA offers the app; it never redirects (2026-09-26).** An automatic redirect to
  `intent://` would trap whoever chose the PWA on Android, and an Android browser leaves for
  an app only from a user gesture, which a page that takes seconds to load no longer has.
  So a question with two answers, the replace dialog one tap away in the PWA.
- **The web link is taken out of the address before `runApp` (2026-09-26).** Flutter web's
  single-entry history keeps the URL it started on in an "origin" entry below its own, where
  a back would bring the invite code back to the address bar; rewriting the entry before the
  engine reads it leaves nothing behind. Reading the route from Flutter
  (`defaultRouteName`) and cleaning up afterwards was the alternative.
- **A link reached while the PWA runs is stripped and the engine reset (2026-09-26, review
  of #237).** The first version handled only the cold start: a `#/join` pushed later stayed
  as a forward entry holding the invite code (Forward replayed the dialog), and the engine
  kept it as its route, so a back to the origin put it back in the address bar, where a
  reload reopened it. Reporting `/` alone (the reviewer's suggestion) resets the route but
  cannot drop the forward entry: the single-entry history only ever replaces its own entry,
  and only a push truncates forward ones. So the entry itself is rewritten on the same
  `popstate`, before the engine's asynchronous step back leaves it. Pushing a clean entry of
  our own was rejected: a second Flutter entry makes a later Back push the home route again.
- **The review asked to document the restored-activity replay; the device run filtered it
  (2026-09-26, review of #237).** Android rebuilds an activity killed in the background from
  its original `VIEW` intent, without the recents flag, and `app_links` delivered it again.
  The review asked for no Kotlin that could not be run where it was written; the Pixel run
  that found it could run it, so `MainActivity` drops a restored activity's intent data
  (`savedInstanceState` non-null) and the dialog does not come back.
- **The unsynced count is read when the question is asked (2026-09-26).** `pendingChanges` is
  the count at the end of the last sync pass: 0 on a cold start, which is exactly how a link
  opens the app, and stale for the second a write waits for its debounced sync.
