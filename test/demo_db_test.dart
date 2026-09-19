// The demo database behind the store screenshots (test/support/demo_db.dart).
//
// Run with DEMO_DB_OUT=<path> to also write the file to import on the phone:
//   DEMO_DB_OUT=/tmp/countscore_demo.db flutter test test/demo_db_test.dart

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/database_service.dart';
import 'package:countscore/services/drift/database.dart';

import 'support/demo_db.dart';

void main() {
  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('countscore_demo_');
    path = '${dir.path}/countscore.db';
    await writeDemoDatabase(path, now: DateTime(2026, 9, 19, 20));
  });
  tearDown(() => dir.delete(recursive: true));

  test('the file is one self-contained database at the current schema',
      () async {
    expect(File('$path-wal').existsSync() && File('$path-wal').lengthSync() > 0,
        isFalse);
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(path);
    addTearDown(db.close);
    expect(await db.getVersion(), DatabaseService.schemaVersion);
  });

  test('six fictional players, ten games, one in progress, one custom type',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase(File(path)));
    addTearDown(db.close);

    final names = (await db
            .customSelect('SELECT name FROM players ORDER BY name')
            .get())
        .map((r) => r.data['name'])
        .toSet();
    expect(names, kDemoPlayers.keys.toSet());

    final games = await DriftGameRepository(db).getAll();
    expect(games, hasLength(kDemoGames.length));
    expect(games.where((g) => g.finishedAt == null).map((g) => g.name),
        ['Annecy']);

    final types = await DriftGameTypeRepository(db).getAll();
    final custom = types.where((t) => t.name == kDemoCustomTypeName).single;
    expect(custom.builtinKey, isNull);
    expect(games.where((g) => g.gameTypeId == custom.id), hasLength(1));

    final typeKeys = {
      for (final g in games)
        types.firstWhere((t) => t.id == g.gameTypeId).builtinKey,
    };
    expect(typeKeys,
        containsAll(['zapzap', 'tarot', 'skyjo', 'belote', 'yahtzee', null]));
  });

  test('every game has a single leader, and every tarot round sums to zero',
      () async {
    for (final g in kDemoGames) {
      for (final round in g.rounds) {
        expect(round, hasLength(g.players.length), reason: g.name);
      }
      final totals = [
        for (var i = 0; i < g.players.length; i++)
          g.rounds.fold<int>(0, (sum, r) => sum + r[i]),
      ];
      final lowest = g.typeKey == 'zapzap' || g.typeKey == 'skyjo';
      final best = lowest
          ? totals.reduce((a, b) => a < b ? a : b)
          : totals.reduce((a, b) => a > b ? a : b);
      expect(totals.where((t) => t == best), hasLength(1), reason: g.name);
      if (g.typeKey == 'tarot') {
        for (final round in g.rounds) {
          expect(round.fold<int>(0, (a, b) => a + b), 0);
        }
      }
    }
  });

  test('every player has the five finished games a ranking needs', () {
    for (final name in kDemoPlayers.keys) {
      final finished =
          kDemoGames.where((g) => g.finished && g.players.contains(name));
      expect(finished.length, greaterThanOrEqualTo(5), reason: name);
    }
  });

  test('the scores in the file are the ones declared', () async {
    final db = AppDatabase.forTesting(NativeDatabase(File(path)));
    addTearDown(db.close);
    final rows = await db.customSelect(
      'SELECT g.name AS game, gp.name AS player, SUM(s.value) AS total '
      'FROM scores s JOIN game_players gp ON gp.id = s.playerId '
      'JOIN games g ON g.id = gp.gameId GROUP BY gp.id',
    ).get();
    final totals = {
      for (final r in rows)
        '${r.data['game']}/${r.data['player']}': r.data['total'] as int,
    };
    expect(totals['Annecy/Emma'], 14);
    expect(totals['Lisboa/Sofia'], 104);
    expect(totals, hasLength(
        kDemoGames.fold<int>(0, (n, g) => n + g.players.length)));
  });

  test('writes the database to DEMO_DB_OUT when it is set', () async {
    final out = Platform.environment['DEMO_DB_OUT'];
    if (out == null || out.isEmpty) {
      markTestSkipped('DEMO_DB_OUT not set');
      return;
    }
    final target = File(out);
    if (target.existsSync()) target.deleteSync();
    await writeDemoDatabase(out);
    expect(target.existsSync(), isTrue);
    // ignore: avoid_print
    print('demo database written to $out');
  });
}
