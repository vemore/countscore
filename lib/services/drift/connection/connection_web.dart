import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Web: Drift over sqlite3.wasm with OPFS/IndexedDB persistence. Fresh install
/// (no legacy DB) so the AppDatabase `onCreate` builds the v9 schema.
///
/// drift_flutter requires explicit URIs for the wasm + worker on web; without
/// them `driftDatabase` throws at startup. Both assets are served from `web/`
/// at the app root, so relative URIs resolve against the base href.
QueryExecutor openConnection() {
  return driftDatabase(
    name: 'countscore',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
