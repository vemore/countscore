import 'package:sqlite3/wasm.dart';

/// The IndexedDB database drift stores the file in: the `name` passed to
/// `driftDatabase` in `lib/services/drift/connection/connection_web.dart`.
const _dbName = 'countscore';

/// The path of the database file inside it (drift's `WasmDatabase`).
const _path = '/database';

/// Opens the database file as IndexedDB holds it right now, read-only, and
/// hands [read] a `select`; null when IndexedDB holds no such database (drift
/// chose another storage, and this probe no longer sees what a reload reads).
///
/// Everything drift's worker has not flushed yet is invisible here, exactly
/// as it would be to the page after a reload.
Future<T?> readPersistedDatabase<T>(
  T Function(List<Map<String, Object?>> Function(String sql) select) read,
) async {
  final names = await IndexedDbFileSystem.databases();
  if (names != null && !names.contains(_dbName)) return null;

  final fs = await IndexedDbFileSystem.open(
    dbName: _dbName,
    vfsName: 'reload-probe',
    // Never write back: this is a reader beside the app's own worker.
    writeAutomatically: false,
  );
  if (fs.xAccess(_path, 0) == 0) return null;

  final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
  sqlite3.registerVirtualFileSystem(fs);
  final db = sqlite3.open(_path, vfs: 'reload-probe', mode: OpenMode.readOnly);
  try {
    return read((sql) => [for (final row in db.select(sql)) Map.of(row)]);
  } finally {
    db.close();
    sqlite3.unregisterVirtualFileSystem(fs);
  }
}
