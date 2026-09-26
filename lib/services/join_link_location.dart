// The PWA's address bar, for a configuration link (`#/join?s=…&g=…`): taken out of
// it once before the app starts, and the Android hand-over navigated to from it.
// On native there is no address bar: the stub reads nothing and opens nothing.
// `dart.library.io` is only available on native, as in pwa_update.dart.
export 'join_link_location_web.dart' if (dart.library.io) 'join_link_location_stub.dart';
