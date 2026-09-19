/// What a reload of the PWA would read back from IndexedDB.
///
/// A reload cannot happen inside an integration test — the test runs in the
/// page — so the reload tests read the stored database the way the next page
/// load does: a fresh file system over the same IndexedDB, and a fresh SQLite.
/// Only the web has such a store; elsewhere [readPersistedDatabase] is null.
library;

export 'persisted_db_stub.dart' if (dart.library.js_interop) 'persisted_db_web.dart';
