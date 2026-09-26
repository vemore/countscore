import 'dart:async';

import 'package:flutter/widgets.dart';

import '../utils/config_link.dart';

/// Every configuration link this app receives, held until the home screen reads
/// it ([JoinLinkListener]) and handed over exactly once:
///
/// - on the web, the `#/join?…` route the page was opened on ([initialRoute],
///   taken out of the address bar before `runApp`), then any `#/join` route
///   pushed while the PWA runs (the address edited, or an installed PWA
///   navigated to a link that differs from its address by the hash alone): as a
///   [WidgetsBindingObserver] registered before `runApp`, it answers those route
///   pushes before `WidgetsApp` does, which would look for a named route and
///   fail;
/// - on Android, `countscore://join?…` intents ([listenTo] on `app_links`'
///   stream, which delivers the launch intent once, then each new intent, and
///   skips a relaunch from the recents screen).
///
/// Links received before a reader is attached wait for it, so a cold start
/// loses none; a link is never replayed, so no rebuild or resume opens it again.
class JoinLinkInbox with WidgetsBindingObserver {
  JoinLinkInbox({String? initialRoute}) {
    if (initialRoute != null) add(initialRoute);
  }

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

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async {
    final route = routeInformation.uri.toString();
    if (!isConfigLinkRoute(route)) return false;
    add(route);
    return true;
  }
}

/// Reads what a [JoinLinkInbox] holds: a PWA hash route (`/join?…`) or a full
/// link in either shape. Null when it is not a valid configuration link.
ConfigLink? parseReceivedConfigLink(String link) =>
    link.startsWith('/') ? parseConfigRoute(link) : parseConfigLink(link);
