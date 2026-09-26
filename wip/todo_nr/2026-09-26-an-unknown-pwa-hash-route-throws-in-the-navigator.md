# An unknown PWA hash route throws in the Navigator instead of opening the home screen

- **Noted:** 2026-09-26 — feat/config-share-join-link, while making `#/join` a route the PWA answers
- **Theme:** web
- **Area:** web
- **Blocks release:** no

`MaterialApp` in `lib/main.dart` has a `home` and no `routes`, `onGenerateRoute` or
`onUnknownRoute`. A hash route the PWA does not know, typed into the address bar while it runs
(`#/foo`), reaches `WidgetsApp.didPushRouteInformation`, which calls `pushNamed('/foo')`: the
Navigator throws `Could not find a generator for route RouteSettings("/foo", null)`, reported
as a Flutter error, and the page stays where it was. On a cold start with such a hash,
`Navigator.defaultGenerateInitialRoutes` reports "Could not navigate to initial route" in a
debug build before falling back to `/`. Seen with `#/join` before
`JoinLinkInbox` answered it (a test without the inbox registered fails with that error:
`test/widgets/join_link_listener_test.dart`, *a #/join pushed while the PWA runs*). Harmless
to data, noisy in the console, and any old link with another route shape would hit it.

**Fix:** an `onUnknownRoute` (or `onGenerateRoute` returning the home route) on `MaterialApp`,
so any unknown route opens the home screen, with a widget test pushing `/foo`.

**Acceptance:**
- Pushing an unknown route while the app runs reports no error and leaves the home screen showing (widget test).
- A cold start on an unknown hash route opens the home screen with no error in a debug build.
