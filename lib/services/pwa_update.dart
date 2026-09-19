// A new build of the PWA waiting to take over (web/service_worker.js), and the reload
// that applies it. On native there is no such thing: the stub never reports one.
// `dart.library.io` is only available on native, as in drift/connection/connection.dart.
export 'pwa_update_web.dart' if (dart.library.io) 'pwa_update_stub.dart';
