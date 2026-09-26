// The v19 -> v20 step: the built-in types that play to a last survivor (ZapZap,
// Rami, 6 qui prend) get `lastPlayerOver` when their row has no game-over
// condition at all. feat/last-player-standing (2026-09-20) seeded it on a new
// database only, so an older install or group never ended a ZapZap by itself
// (wip/done/2026-09-23-a-game-with-one-player-left-does-not-reliably-end-itself.md).
// This file replaces migration_last_player_standing_test.dart, which asserted
// the opposite.
//
// Built on the model of migration_v18_to_v19_test.dart: a current database is
// stepped back to v19, its rows written the way an older install stored them,
// then reopened through both engines' real upgrade callbacks and once more
// straight through `applyV20`.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:countscore/services/database_service.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/schema_steps.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('countscore_v20_');
    path = '${dir.path}/countscore.db';
  });
  tearDown(() => dir.delete(recursive: true));

  late int deletedZapzap; // an older ZapZap, deleted, no condition

  /// A current database stepped back to v19, holding:
  /// - ZapZap with no condition (group `e802...` in production), unless
  ///   [zapzapCondition] gives it one the user set, and linked into a group so
  ///   the capture trigger has a row to see;
  /// - Rami with a condition the user set (`firstPlayerOver`/500);
  /// - 6 qui prend with no condition and the pre-2026-09-19 threshold of 66;
  /// - Uno as seeded (`firstPlayerOver`/500), which v20 must not touch;
  /// - a deleted ZapZap with no condition, which stays as it is.
  Future<void> writeV19File({List<Object?>? zapzapCondition}) async {
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: DatabaseService.schemaVersion,
        onCreate: (db, v) => DatabaseService.instance.createDB(db, v),
      ),
    );
    Future<void> setCondition(String key, Object? type, Object? threshold,
            [Map<String, Object?> more = const {}]) =>
        db.update(
          'game_types',
          {
            'gameOverConditionType': type,
            'gameOverThreshold': threshold,
            'updated_at': 1,
            ...more,
          },
          where: 'builtin_key = ?',
          whereArgs: [key],
        );

    await setCondition('zapzap', zapzapCondition?[0], zapzapCondition?[1]);
    await setCondition('rami', 'firstPlayerOver', 500);
    await setCondition('six_nimmt', null, null, {'playerDeadThreshold': 66});

    deletedZapzap = await db.insert('game_types', {
      'builtin_key': 'zapzap',
      'name': 'ZapZap',
      'iconCodePoint': 0xe000,
      'cardColorValue': 0xFF000000,
      'isLowestScoreWins': 1,
      'isDefault': 0,
      'playerDeadConditionType': 'over',
      'playerDeadThreshold': 100,
      'uuid': 'zapzap-deleted',
      'created_at': 1,
      'updated_at': 1,
      'deleted_at': 5,
    });

    final zapzapUuid = (await db.query('game_types',
            columns: ['uuid'],
            where: 'builtin_key = ? AND deleted_at IS NULL',
            whereArgs: ['zapzap']))
        .single['uuid'];
    await db.insert('group_links', {
      'group_id': 'g-1',
      'entity_type': 'game_type',
      'local_uuid': zapzapUuid,
      'remote_uuid': 'remote-zapzap',
    });
    await db.delete('outbox');

    await db.execute('PRAGMA user_version = 19');
    await db.close();
  }

  /// `builtin_key -> [gameOverConditionType, gameOverThreshold]`, live rows.
  Map<String, List<Object?>> conditions(List<Map<String, Object?>> rows) => {
        for (final r in rows)
          if (r['builtin_key'] != null && r['deleted_at'] == null)
            r['builtin_key'] as String: [
              r['gameOverConditionType'],
              r['gameOverThreshold'],
            ],
      };

  void expectSeeded(Map<String, List<Object?>> state,
      {List<Object?> zapzap = const ['lastPlayerOver', 100]}) {
    expect(state['zapzap'], zapzap, reason: 'ZapZap');
    expect(state['rami'], ['firstPlayerOver', 500],
        reason: 'a condition the user set was overwritten');
    expect(state['six_nimmt'], ['lastPlayerOver', 66],
        reason: 'the end must match the threshold that puts a player out');
    expect(state['uno'], ['firstPlayerOver', 500],
        reason: 'a firstPlayerOver type was touched');
  }

  const selectAll = 'SELECT id, builtin_key, deleted_at, '
      'gameOverConditionType, gameOverThreshold FROM game_types';

  test('native: the sqflite chain sets lastPlayerOver/100 on a NULL-condition '
      'ZapZap', () async {
    await writeV19File();

    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    expect(await db.getVersion(), DatabaseService.schemaVersion);
    final rows = await db.rawQuery(selectAll);
    expectSeeded(conditions(rows));
    final deleted = rows.singleWhere((r) => r['id'] == deletedZapzap);
    expect(deleted['gameOverConditionType'], isNull,
        reason: 'a deleted row was rewritten');
  });

  test("web: Drift's onUpgrade sets lastPlayerOver/100 on a NULL-condition "
      'ZapZap', () async {
    await writeV19File();

    final db = AppDatabase.forTesting(NativeDatabase(File(path)));
    addTearDown(db.close);

    final rows = await db.customSelect(selectAll).get();
    expectSeeded(conditions(rows.map((r) => r.data).toList()));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, DatabaseService.schemaVersion);
  });

  test('a ZapZap condition the user set is unchanged', () async {
    await writeV19File(zapzapCondition: ['lastPlayerOver', 150]);

    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    expectSeeded(conditions(await db.rawQuery(selectAll)),
        zapzap: ['lastPlayerOver', 150]);
  });

  test('the UPDATE queues the linked row for the server, and replays as a '
      'no-op', () async {
    await writeV19File();
    final db = await databaseFactoryFfi.openDatabase(path);
    addTearDown(db.close);

    await applyV20(db.execute);
    final outbox = await db.query('outbox');
    expect(
        outbox.map((r) => [r['entity_type'], r['entity_uuid'] != null, r['op']]),
        [
          ['game_type', true, 'upsert'],
        ],
        reason: 'only the linked ZapZap is pushed');

    final before = await db.rawQuery('SELECT * FROM game_types ORDER BY id');
    await applyV20(db.execute);
    expect(await db.rawQuery('SELECT * FROM game_types ORDER BY id'), before);
    expect(await db.query('outbox'), hasLength(1),
        reason: 'a replay matched a row');
  });

  test('a row whose elimination the user turned to "under" is left alone',
      () async {
    await writeV19File();
    final db = await databaseFactoryFfi.openDatabase(path);
    addTearDown(db.close);
    await db.update('game_types', {'playerDeadConditionType': 'under'},
        where: 'builtin_key = ? AND deleted_at IS NULL',
        whereArgs: ['six_nimmt']);

    await applyV20(db.execute);
    final six = (await db.query('game_types',
            where: 'builtin_key = ? AND deleted_at IS NULL',
            whereArgs: ['six_nimmt']))
        .single;
    expect(six['gameOverConditionType'], isNull);
  });

  test('a row with no elimination at all is left alone', () async {
    await writeV19File();
    final db = await databaseFactoryFfi.openDatabase(path);
    addTearDown(db.close);
    await db.update('game_types',
        {'playerDeadConditionType': null, 'playerDeadThreshold': null},
        where: 'builtin_key = ? AND deleted_at IS NULL',
        whereArgs: ['zapzap']);

    await applyV20(db.execute);
    final zapzap = (await db.query('game_types',
            where: 'builtin_key = ? AND deleted_at IS NULL',
            whereArgs: ['zapzap']))
        .single;
    expect(zapzap['gameOverConditionType'], isNull,
        reason: 'a type with nobody ever out got a last-player-standing end');
    expect(zapzap['gameOverThreshold'], isNull);
  });
}
