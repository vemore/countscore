import 'dart:js_interop';

import '../utils/config_link.dart';

@JS('location')
external _Location get _location;

@JS('history')
external _History get _history;

@JS('addEventListener')
external void _addEventListener(String type, JSFunction listener);

extension type _Location._(JSObject _) implements JSObject {
  external String get hash;
  external String get pathname;
  external String get search;
  external void assign(String url);
}

extension type _History._(JSObject _) implements JSObject {
  external JSAny? get state;
  external void replaceState(JSAny? data, String unused, String url);
}

/// The hash route of the current address (what follows `#`), or null.
String? _hashRoute() {
  final hash = _location.hash;
  return hash.length < 2 ? null : hash.substring(1);
}

/// The join route the page was opened on (`/join?s=…&g=…`, what follows `#`),
/// taken out of the address bar: the current history entry is rewritten to the
/// PWA's root, so a reload or a back does not open it again and the invite code
/// does not stay on screen. Null, and nothing rewritten, for any other route.
///
/// Called in `main()` before `runApp`, before Flutter's own history handling
/// reads the address: it then starts on the home route, with no entry left
/// behind that still holds the code.
String? takeJoinRouteFromLocation() {
  final route = _hashRoute();
  if (route == null || !isConfigLinkRoute(route)) return null;
  _history.replaceState(_history.state, '', '${_location.pathname}${_location.search}');
  return route;
}

/// The join route last stripped by [watchJoinRoutesInLocation], until taken.
String? _stripped;

/// Strips the payload of a `#/join?…` reached while the PWA runs (the address
/// edited in the same tab, or an installed PWA sent to a link that differs from
/// its address by the hash), before Flutter's history reads it.
///
/// That navigation adds a history entry of its own. Flutter's single-entry
/// history then records its route and steps back off it (`go(-1)`), which
/// leaves it as a *forward* entry: with the invite code in it, Forward would
/// replay the link and the code would stay in the tab's history. Here, on the
/// same `popstate`, the entry is rewritten to a bare `#/join` — the step back
/// is asynchronous, so the rewrite lands on that entry — and the full route is
/// kept for [takeStrippedJoinRoute]. Flutter then pushes the bare `/join`,
/// which `JoinLinkInbox` answers with the kept route, once, and resets the
/// engine's route to `/`.
///
/// Registered in `main()` before `runApp`, so ahead of the listener Flutter's
/// history adds once the app starts. Should Flutter's run first, it pushes the
/// full route itself; the inbox then drops the kept copy unused.
void watchJoinRoutesInLocation() {
  _addEventListener(
    'popstate',
    ((JSAny? _) {
      final route = _hashRoute();
      if (route == null || route == configLinkRoute || !isConfigLinkRoute(route)) return;
      _stripped = route;
      _history.replaceState(
        _history.state,
        '',
        '${_location.pathname}${_location.search}#$configLinkRoute',
      );
    }).toJS,
  );
}

/// The full route [watchJoinRoutesInLocation] stripped last, once; null when
/// there is none.
String? takeStrippedJoinRoute() {
  final route = _stripped;
  _stripped = null;
  return route;
}

/// Navigates this page to [url]: the `intent://` hand-over, which the browser
/// resolves on the device. Called from a tap, which is the user activation an
/// Android browser requires before it leaves for an app.
void openLinkInPlace(String url) => _location.assign(url);
