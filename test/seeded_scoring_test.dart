// Uno and Président changed scoring direction in feat/game-rules-seeds: both
// now follow the box rule, highest total wins. The decision was "new databases
// only" — a type that already has games would see its finished standings
// reversed if its row were flipped. These tests hold both halves of it:
//
// 1. a fresh database, sqflite and Drift alike, seeds the new scoring;
// 2. a database holding the old lowest-wins rows keeps them through the whole
//    upgrade chain, because no migration step touches `isLowestScoreWins`.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:countscore/models/game_type.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/database_service.dart';
import 'package:countscore/services/drift/database.dart';

/// `game_types` and `games` as of v4 — the oldest shape whose upgrade still
/// re-seeds game types — with the minimum the chain needs to run.
Future<void> _createV4Schema(Database db) async {
  await db.execute('''
    CREATE TABLE game_types (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      iconCodePoint INTEGER NOT NULL,
      cardColorValue INTEGER NOT NULL,
      isLowestScoreWins INTEGER NOT NULL,
      isDefault INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE games (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      gameType TEXT NOT NULL DEFAULT 'ZapZap',
      isLowestScoreWins INTEGER NOT NULL,
      createdAt TEXT NOT NULL,
      lastModified TEXT,
      gameTypeId INTEGER
    )
  ''');
  await db.execute('''
    CREATE TABLE players (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      gameId INTEGER NOT NULL,
      name TEXT NOT NULL,
      orderIndex INTEGER NOT NULL,
      colorValue INTEGER
    )
  ''');
  await db.execute('''
    CREATE TABLE rounds (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      gameId INTEGER NOT NULL,
      roundNumber INTEGER NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE scores (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      playerId INTEGER NOT NULL,
      roundId INTEGER NOT NULL,
      value INTEGER NOT NULL
    )
  ''');
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('countscore_seeds_');
    path = '${dir.path}/countscore.db';
  });
  tearDown(() => dir.delete(recursive: true));

  Future<Map<String, Object?>> row(Database db, String key) async =>
      (await db.query('game_types', where: 'builtin_key = ?', whereArgs: [key]))
          .single;

  test('a fresh sqflite database seeds Uno and Président as highest-wins',
      () async {
    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);

    final uno = await row(db, 'uno');
    expect(uno['isLowestScoreWins'], 0);
    expect(uno['gameOverConditionType'], 'firstPlayerOver');
    expect(uno['gameOverThreshold'], 500);

    final president = await row(db, 'president');
    expect(president['isLowestScoreWins'], 0);
    expect(president['gameOverConditionType'], 'firstPlayerOver');
    expect(president['gameOverThreshold'], 10);
  });

  test('a fresh Drift database seeds Uno and Président as highest-wins',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final types = await DriftGameTypeRepository(db).getAll();
    final byKey = {for (final t in types) t.builtinKey: t};

    expect(byKey['uno']!.isLowestScoreWins, isFalse);
    expect(byKey['uno']!.gameOverConditionType,
        GameOverConditionType.firstPlayerOver);
    expect(byKey['uno']!.gameOverThreshold, 500);
    expect(byKey['president']!.isLowestScoreWins, isFalse);
    expect(byKey['president']!.gameOverThreshold, 10);
  });

  test('an existing lowest-wins Uno or Président row keeps its direction',
      () async {
    // Seeded the way every install before feat/game-rules-seeds seeded them.
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, _) => _createV4Schema(db),
      ),
    );
    for (final name in ['ZapZap', 'Uno', 'Scrabble', 'Autre', 'Président']) {
      await old.insert('game_types', {
        'name': name,
        'iconCodePoint': 0xe000,
        'cardColorValue': 0xFF000000,
        'isLowestScoreWins': name == 'Scrabble' || name == 'Autre' ? 0 : 1,
        'isDefault': 1,
      });
    }
    await old.close();

    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);
    expect(await db.getVersion(), DatabaseService.schemaVersion);

    final uno = await row(db, 'uno');
    expect(uno['isLowestScoreWins'], 1,
        reason: 'no migration may reverse the standings of existing Uno games');
    expect(uno['gameOverThreshold'], isNull);

    final president = await row(db, 'president');
    expect(president['isLowestScoreWins'], 1,
        reason: 'no migration may reverse the standings of existing Président games');
    // The v5 step set the threshold it has always set; only a new row gets 10.
    expect(president['gameOverThreshold'], 11);
  });
}
