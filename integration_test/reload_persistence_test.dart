// A reload of the PWA must read back what the page wrote
// (wip/done/2026-09-19-pwa-reload-reruns-the-database-creation.md).
//
// drift's IndexedDB storage keeps the database in memory and writes it to
// IndexedDB on a flush. Before the fix the schema version and every committed
// transaction were never flushed: a reload found `user_version` 0, reran
// `onCreate` (which then failed on the built-in types' unique index), and a
// deleted game came back. A reload cannot happen inside the test, so the test
// reads IndexedDB the way the next page load would — see support/persisted_db.dart.
//
// Web only (a device keeps a plain file, written synchronously):
//
//   chromedriver --port=4444 &
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/reload_persistence_test.dart \
//     -d web-server --browser-name=chrome --headless

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:countscore/main.dart' as app;
import 'package:countscore/models/game.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/drift/database.dart';

import 'support/persisted_db.dart';

/// What a reload would read: the schema version, the live built-in types and
/// the live games' names.
typedef _Snapshot = ({int version, List<String> builtins, List<String> games});

Future<_Snapshot> _persisted() async {
  final snapshot = await readPersistedDatabase<_Snapshot>((select) => (
        version: select('PRAGMA user_version').single.values.single as int,
        builtins: [
          for (final r in select('SELECT builtin_key FROM game_types '
              'WHERE builtin_key IS NOT NULL AND deleted_at IS NULL ORDER BY id'))
            r['builtin_key'] as String,
        ],
        games: [
          for (final r in select('SELECT name FROM games WHERE deleted_at IS NULL'))
            r['name'] as String,
        ],
      ));
  expect(snapshot, isNotNull,
      reason: 'IndexedDB holds no "countscore" database: drift picked another '
          'storage, and this probe no longer reads what a reload reads');
  return snapshot!;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a reload reads back the schema version, the types and a deletion',
      (tester) async {
    app.main();
    await tester.pumpAndSettle();

    final db = AppDatabase.instance;
    // The app has opened the database; any statement waits for that.
    await db.customSelect('SELECT 1').get();

    final builtins = [
      for (final t in GameType.defaultGameTypes())
        if (t.builtinKey != null) t.builtinKey!,
    ];

    // Straight after the first open, before anything else is written: the
    // version drift set once `onCreate` ran must already be stored.
    var stored = await _persisted();
    expect(stored.version, db.schemaVersion);
    expect(stored.builtins, builtins);

    // A deletion is a transaction; its commit must be stored as well.
    final games = DriftGameRepository(db);
    final kept = await games.create(Game(name: 'Reload kept', isLowestScoreWins: false));
    final gone = await games.create(Game(name: 'Reload gone', isLowestScoreWins: false));
    await games.delete(gone);

    stored = await _persisted();
    expect(stored.version, db.schemaVersion);
    expect(stored.builtins, builtins);
    expect(stored.games, contains('Reload kept'));
    expect(stored.games, isNot(contains('Reload gone')));

    await games.delete(kept);
    expect((await _persisted()).games, isNot(contains('Reload kept')));
  }, skip: !kIsWeb);
}
