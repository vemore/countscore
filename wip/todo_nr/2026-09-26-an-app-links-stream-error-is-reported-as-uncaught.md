# An error on the app_links stream is reported as an uncaught error

- **Noted:** 2026-09-26 — independent review of #237 (finding 5), from the local session that merged it
- **Theme:** groups-v2
- **Area:** android
- **Blocks release:** no

`JoinLinkInbox.listenTo` (`lib/services/join_link_inbox.dart`) is `links.listen(add)` with
no `onError`. An error event from `app_links`' EventChannel (a malformed intent the plugin
fails to read) would surface as an uncaught zone error, reported like a crash, where a
malformed link is otherwise ignored silently.

**Fix:** `links.listen(add, onError: (Object e, StackTrace s) { /* log and ignore */ })`,
reporting through `FlutterError.reportError` with `library: 'join link'` like the listener.

**Acceptance:**
- A unit test feeding an error into the stream passed to `listenTo` sees no uncaught error, and a link added after it is still delivered.
