// Picks the platform-specific Drift connection. `dart.library.io` is only
// available on native (mobile/desktop); web falls back to the wasm connection.
export 'connection_web.dart' if (dart.library.io) 'connection_native.dart';
