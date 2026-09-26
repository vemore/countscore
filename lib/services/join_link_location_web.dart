import 'dart:js_interop';

import '../utils/config_link.dart';

@JS('location')
external _Location get _location;

@JS('history')
external _History get _history;

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

/// The join route the page was opened on (`/join?s=…&g=…`, what follows `#`),
/// taken out of the address bar: the current history entry is rewritten to the
/// PWA's root, so a reload or a back does not open it again and the invite code
/// does not stay on screen. Null, and nothing rewritten, for any other route.
///
/// Called in `main()` before `runApp`, before Flutter's own history handling
/// reads the address: it then starts on the home route, with no entry left
/// behind that still holds the code.
String? takeJoinRouteFromLocation() {
  final hash = _location.hash;
  if (hash.length < 2) return null;
  final route = hash.substring(1);
  if (!isConfigLinkRoute(route)) return null;
  _history.replaceState(_history.state, '', '${_location.pathname}${_location.search}');
  return route;
}

/// Navigates this page to [url]: the `intent://` hand-over, which the browser
/// resolves on the device. Called from a tap, which is the user activation an
/// Android browser requires before it leaves for an app.
void openLinkInPlace(String url) => _location.assign(url);
