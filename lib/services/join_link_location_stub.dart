/// Native: there is no page address to read a join route from.
String? takeJoinRouteFromLocation() => null;

/// Native: no address bar to watch.
void watchJoinRoutesInLocation() {}

/// Native: nothing is ever stripped.
String? takeStrippedJoinRoute() => null;

/// Native: never called, the hand-over exists only in an Android browser.
void openLinkInPlace(String url) {}
