// The v16 → v17 step: the keyless copies of built-in types that the old PWA
// reload bug left behind are soft-deleted, unless a game points at them.
//
// Built on the model of migration_v15_to_v16_test.dart: a current database is
// stepped back to v16 with the copies a reload-bug browser holds, then opened
// through both engines' real upgrade callbacks — sqflite's chain on native,
// Drift's `onUpgrade` on web — and once more straight through `applyV17`.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:countscore/services/database_service.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/sync/sync_schema.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('countscore_v17_');
    path = '${dir.path}/countscore.db';
  });
  tearDown(() => dir.delete(recursive: true));

  var seq = 0;

  /// Inserts a keyless, group-less copy of the built-in row [key], as the
  /// pre-#153 reload wrote it and v15 stripped it. Returns its id.
  Future<int> copyOf(Database db, String key,
      {Map<String, Object?> change = const {}}) async {
    final original = (await db
            .query('game_types', where: 'builtin_key = ?', whereArgs: [key]))
        .single;
    final row = Map<String, Object?>.from(original)
      ..remove('id')
      ..['builtin_key'] = null
      ..['uuid'] = 'copy-${seq++}'
      ..addAll(change);
    return db.insert('game_types', row);
  }

  Future<void> gameOn(Database db, int typeId, {bool deleted = false}) =>
      db.insert('games', {
        'name': 'Partie $typeId',
        'gameTypeId': typeId,
        'isLowestScoreWins': 0,
        'createdAt': '2026-09-13T20:00:00.000',
        'uuid': 'game-${seq++}',
        'created_at': 1,
        'updated_at': 1,
        'deleted_at': deleted ? 2 : null,
      });

  // The rows the acceptance names, in the v16 file.
  late int zapzapCopy;
  late int tarotCopyWithGame;
  late int beloteCopyWithDeletedGame;
  late int myTarot;
  late int unoCopyWithRules;
  late int renamedCopy;

  Future<void> writeV16File() async {
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: DatabaseService.schemaVersion,
        onCreate: (db, v) => DatabaseService.instance.createDB(db, v),
      ),
    );
    zapzapCopy = await copyOf(db, 'zapzap');
    tarotCopyWithGame = await copyOf(db, 'tarot');
    await gameOn(db, tarotCopyWithGame);
    beloteCopyWithDeletedGame = await copyOf(db, 'belote');
    await gameOn(db, beloteCopyWithDeletedGame, deleted: true);
    // The user's own "Tarot": the built-in name, a different scoring.
    myTarot = await copyOf(db, 'tarot', change: {
      'isLowestScoreWins': 1,
      'gameOverConditionType': 'firstPlayerOver',
      'gameOverThreshold': 500,
      'isDefault': 0,
    });
    unoCopyWithRules =
        await copyOf(db, 'uno', change: {'rules': 'Nos règles.'});
    renamedCopy =
        await copyOf(db, 'skyjo', change: {'name': 'Skyjo du dimanche'});
    await db.execute('PRAGMA user_version = 16');
    await db.close();
  }

  const liveKeyedSql = 'SELECT COUNT(*) AS c FROM game_types '
      'WHERE builtin_key IS NOT NULL AND deleted_at IS NULL';

  Map<int, Object?> byId(List<Map<String, Object?>> rows) =>
      {for (final r in rows) r['id'] as int: r['deleted_at']};

  void expectDeduped(Map<int, Object?> deletedAtById, int liveKeyed) {
    expect(deletedAtById[zapzapCopy], isNotNull,
        reason: 'the unused keyless zapzap copy is still live');
    for (final kept in {
      'the copy with a game': tarotCopyWithGame,
      'the copy with a deleted game': beloteCopyWithDeletedGame,
      'the user type scoring differently': myTarot,
      'the copy with its own rules': unoCopyWithRules,
      'the copy under another name': renamedCopy,
    }.entries) {
      expect(deletedAtById[kept.value], isNull, reason: '${kept.key} was deleted');
    }
    expect(liveKeyed, 22, reason: 'a built-in row was touched');
  }

  test('native: the sqflite chain soft-deletes the unused keyless copy',
      () async {
    await writeV16File();

    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    expect(await db.getVersion(), 17);
    final liveKeyed = (await db.rawQuery(liveKeyedSql)).single['c'] as int;
    expectDeduped(byId(await db.query('game_types')), liveKeyed);
    final copy = (await db
            .query('game_types', where: 'id = ?', whereArgs: [zapzapCopy]))
        .single;
    expect(copy['updated_at'], copy['deleted_at'],
        reason: 'a tombstone carries its time');
  });

  test("web: Drift's onUpgrade soft-deletes the unused keyless copy",
      () async {
    await writeV16File();

    final db = AppDatabase.forTesting(NativeDatabase(File(path)));
    addTearDown(db.close);

    final rows =
        await db.customSelect('SELECT id, deleted_at FROM game_types').get();
    final liveKeyed =
        (await db.customSelect(liveKeyedSql).getSingle()).data['c'] as int;
    expectDeduped(byId(rows.map((r) => r.data).toList()), liveKeyed);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 17);
  });

  test('applyV17 leaves a shared copy alone and replays as a no-op', () async {
    await writeV16File();
    final db = await databaseFactoryFfi.openDatabase(path);
    addTearDown(db.close);
    final shared = await copyOf(db, 'rami', change: {'group_id': 'g-1'});

    await applyV17(db.execute);
    final once = await db.query('game_types', orderBy: 'id');
    await applyV17(db.execute);

    expect(await db.query('game_types', orderBy: 'id'), once);
    expect(byId(once)[shared], isNull,
        reason: 'a shared row is not a local copy');
    expectDeduped(
        byId(once), (await db.rawQuery(liveKeyedSql)).single['c'] as int);
  });
}
