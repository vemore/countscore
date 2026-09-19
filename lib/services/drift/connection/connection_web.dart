import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'persistence_flush.dart';

/// Web: Drift over sqlite3.wasm. drift_flutter picks the storage by probing the
/// browser; without cross-origin isolation (no COOP/COEP headers, as in every
/// deployment of the PWA) Chromium gets `sharedIndexedDb`: the file lives in
/// memory in a shared worker and is written to IndexedDB on a flush. No legacy
/// database, so the AppDatabase `onCreate` builds the current schema.
///
/// drift_flutter requires explicit URIs for the wasm + worker on web; without
/// them `driftDatabase` throws at startup. Both assets are served from `web/`
/// at the app root, so relative URIs resolve against the base href.
///
/// [PersistenceFlushInterceptor] makes the schema version and every committed
/// transaction reach IndexedDB before the call returns; without it a reload
/// reran `onCreate` and brought deleted games back.
QueryExecutor openConnection() {
  return driftDatabase(
    name: 'countscore',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  ).interceptWith(PersistenceFlushInterceptor());
}
