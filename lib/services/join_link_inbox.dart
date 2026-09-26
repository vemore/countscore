import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../utils/config_link.dart';

/// Every configuration link this app receives, held until the home screen reads
/// it ([JoinLinkListener]) and handed over once per delivery:
///
/// - on the web, the `#/join?…` route the page was opened on ([initialRoute],
///   taken out of the address bar before `runApp`), then any `#/join` route
///   pushed while the PWA runs (the address edited, or an installed PWA
///   navigated to a link that differs from its address by the hash alone): as a
///   [WidgetsBindingObserver] registered before `runApp`, it answers those route
///   pushes before `WidgetsApp` does, which would look for a named route and
///   fail. Such a push then resets the engine's route to `/` (see
///   [didPushRouteInformation]);
/// - on Android, `countscore://join?…` intents ([listenTo] on `app_links`'
///   stream, which delivers the launch intent once, then each new intent, and
///   skips a relaunch from the recents screen).
///
/// Links received before a reader is attached wait for it, so a cold start
/// loses none, and the inbox never replays one: no rebuild or resume of the
/// running app opens a link again. One case does, on Android: when the system
/// has killed the app in the background and the user comes back to it with
/// Back (not from the recents screen), Android recreates the activity from the
/// intent that first opened it, `app_links` delivers that intent again, and the
/// dialog asks again. Nothing changes unless the user confirms.
class JoinLinkInbox with WidgetsBindingObserver {
  JoinLinkInbox({String? initialRoute, this.takeStrippedRoute}) {
    if (initialRoute != null) add(initialRoute);
  }

  /// The full route the page's address held before it was stripped to a bare
  /// `#/join` (`takeStrippedJoinRoute`, web only).
  final String? Function()? takeStrippedRoute;

  final _waiting = <String>[];
  void Function(String link)? _reader;

  /// Hands [link] (a full link, or a hash route starting with `/`) to the reader,
  /// or keeps it until one attaches.
  void add(String link) {
    final reader = _reader;
    if (reader == null) {
      _waiting.add(link);
    } else {
      reader(link);
    }
  }

  /// Makes [reader] the one that receives links, starting with those waiting.
  void attach(void Function(String link) reader) {
    _reader = reader;
    final waiting = List.of(_waiting);
    _waiting.clear();
    waiting.forEach(reader);
  }

  /// Stops [reader] receiving links, if it still is the one attached.
  void detach(void Function(String link) reader) {
    if (identical(_reader, reader)) _reader = null;
  }

  /// Adds every link [links] brings.
  StreamSubscription<String> listenTo(Stream<String> links) => links.listen(add);

  /// A `#/join` pushed while the PWA runs. The route is taken — the full one
  /// kept when the address was stripped to a bare `#/join`, else the one pushed
  /// — and the engine is told the app is on `/` again: Flutter web's
  /// single-entry history keeps the last route it was pushed and puts it back
  /// in the address bar, in a new entry, the next time it rebuilds its entry
  /// (a back to its origin), where a reload would open the link again.
  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async {
    final route = routeInformation.uri.toString();
    if (!isConfigLinkRoute(route)) return false;
    // Always taken, so a copy kept while the full route was pushed anyway
    // cannot come back with a later bare `/join` (Forward).
    final stripped = takeStrippedRoute?.call();
    add(route == configLinkRoute && stripped != null ? stripped : route);
    unawaited(SystemNavigator.routeInformationUpdated(uri: Uri.parse('/'), replace: true));
    return true;
  }
}

/// Reads what a [JoinLinkInbox] holds: a PWA hash route (`/join?…`) or a full
/// link in either shape. Null when it is not a valid configuration link.
ConfigLink? parseReceivedConfigLink(String link) =>
    link.startsWith('/') ? parseConfigRoute(link) : parseConfigLink(link);
