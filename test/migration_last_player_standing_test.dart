// Seeding `lastPlayerOver` on ZapZap, Rami and 6 qui prend changes what a
// *new* database holds. An existing install keeps the row it already has — as
// with Uno and Président (`lib/models/game_type.dart`), no migration rewrites
// one: a game in progress must not gain an end its players did not agree to.
//
// Built on the model of migration_v16_to_v17_test.dart: a current database is
// stepped back, its three rows stripped of the new condition the way an old
// install stored them, then reopened through both engines' upgrade callbacks.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:countscore/services/database_service.dart';
import 'package:countscore/services/drift/database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('countscore_lps_');
    path = '${dir.path}/countscore.db';
  });
  tearDown(() => dir.delete(recursive: true));

  const keys = ['zapzap', 'rami', 'six_nimmt'];

  /// A database as an install from before feat/last-player-standing holds it:
  /// the three elimination types with no game-over condition at all.
  Future<void> writeOlderFile() async {
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: DatabaseService.schemaVersion,
        onCreate: (db, v) => DatabaseService.instance.createDB(db, v),
      ),
    );
    await db.update(
      'game_types',
      {'gameOverConditionType': null, 'gameOverThreshold': null},
      where: 'builtin_key IN (?, ?, ?)',
      whereArgs: keys,
    );
    await db.execute('PRAGMA user_version = 16');
    await db.close();
  }

  test('native: the sqflite chain leaves the three rows condition-less',
      () async {
    await writeOlderFile();

    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    for (final key in keys) {
      final row = (await db
              .query('game_types', where: 'builtin_key = ?', whereArgs: [key]))
          .single;
      expect(row['gameOverConditionType'], isNull, reason: key);
      expect(row['gameOverThreshold'], isNull, reason: key);
    }
  });

  test("web: Drift's onUpgrade leaves the three rows condition-less", () async {
    await writeOlderFile();

    final db = AppDatabase.forTesting(NativeDatabase(File(path)));
    addTearDown(db.close);

    final rows = await db
        .customSelect('SELECT builtin_key, gameOverConditionType, '
            'gameOverThreshold FROM game_types '
            "WHERE builtin_key IN ('zapzap', 'rami', 'six_nimmt')")
        .get();

    expect(rows.length, keys.length);
    for (final row in rows) {
      final key = row.data['builtin_key'];
      expect(row.data['gameOverConditionType'], isNull, reason: '$key');
      expect(row.data['gameOverThreshold'], isNull, reason: '$key');
    }
  });
}
