// The v23 -> v24 step: one membership per (game, player) among live rows only
// (wip/done/2026-11-25-a-pulled-membership-upsert-undoes-a-delete.md). Before
// it, the unique index counted tombstones, so a player removed from a shared
// game could not be added back.
//
// Built on the model of migration_v22_to_v23_test.dart: a current database is
// stepped back to v23 — the v9 index put back in place of the v24 one — and
// filled with a shared game Alice was removed from, then reopened through both
// engines' real upgrade callbacks and once more straight through `applyV24`.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:countscore/models/player.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/database_service.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/schema_steps.dart';

const _group = '11111111-1111-4111-8111-111111111111';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dir;
  late String path;
  late int game;
  late int alice;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('countscore_v24_');
    path = '${dir.path}/countscore.db';
  });
  tearDown(() => dir.delete(recursive: true));

  /// A current database stepped back to v23, holding a shared game Alice was
  /// removed from: her membership is a tombstone.
  Future<void> writeV23File() async {
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: DatabaseService.schemaVersion,
        onCreate: (db, v) => DatabaseService.instance.createDB(db, v),
      ),
    );
    await db.execute('DROP INDEX idx_game_players_live');
    await db.execute(
        'CREATE UNIQUE INDEX idx_game_players_unique ON game_players(gameId, player_id)');
    alice = await db.insert('players',
        {'name': 'Alice', 'uuid': 'alice', 'created_at': 1, 'updated_at': 1});
    game = await db.insert('games', {
      'name': 'Mardi',
      'isLowestScoreWins': 1,
      'createdAt': '2026-11-24T20:00:00.000',
      'uuid': 'game',
      'created_at': 1,
      'updated_at': 1,
      'group_id': _group,
    });
    await db.insert('game_players', {
      'gameId': game,
      'player_id': alice,
      'name': 'Alice',
      'orderIndex': 0,
      'uuid': 'removed',
      'created_at': 1,
      'updated_at': 1,
      'deleted_at': 2,
    });
    await db.execute('PRAGMA user_version = 23');
    await db.close();
  }

  /// The membership indexes, by name, with their SQL.
  Future<Map<String, String>> indexes(
          Future<List<Map<String, Object?>>> Function(String sql) query) async =>
      {
        for (final r in await query("SELECT name, sql FROM sqlite_master WHERE type = 'index' "
            "AND name IN ('idx_game_players_unique', 'idx_game_players_live')"))
          r['name'] as String: r['sql'] as String,
      };

  test('native: the index holds over live rows only; a second live row is still refused',
      () async {
    await writeV23File();

    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    expect(await db.getVersion(), DatabaseService.schemaVersion);
    final after = await indexes(db.rawQuery);
    expect(after.keys, ['idx_game_players_live']);
    expect(after.values.single, contains('WHERE deleted_at IS NULL'));

    Map<String, Object?> membership(String uuid) => {
          'gameId': game,
          'player_id': alice,
          'name': 'Alice',
          'orderIndex': 1,
          'uuid': uuid,
          'created_at': 3,
          'updated_at': 3,
        };
    await db.insert('game_players', membership('back'));
    await expectLater(db.insert('game_players', membership('twice')), throwsA(anything));
  });

  test("web: Drift's onUpgrade lets Alice be added back", () async {
    await writeV23File();

    final db = AppDatabase.forTesting(NativeDatabase(File(path)));
    addTearDown(db.close);

    final players = DriftPlayerRepository(db);
    await players.create(Player(gameId: game, name: 'Alice', orderIndex: 1));
    expect([for (final p in await players.getByGame(game)) p.name], ['Alice']);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, db.schemaVersion);
    expect((await indexes((sql) async =>
            [for (final r in await db.customSelect(sql).get()) r.data]))
        .keys, ['idx_game_players_live']);
  });

  test('applyV24 replays on a v24 database without a change', () async {
    await writeV23File();
    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);
    final before = await indexes(db.rawQuery);

    await applyV24(db.execute);

    expect(await indexes(db.rawQuery), before);
  });
}
