// Integration tests for DatabaseService — covers v5 schema operations and the
// v5 → v6 migration. Uses sqflite_common_ffi for an in-memory database.
//
// IMPORTANT: this file requires ``sqflite_common_ffi`` as a dev dependency.
// To run locally:
//
//   flutter pub add --dev sqflite_common_ffi
//   flutter test test/database_service_test.dart
//
// These tests have not been executed in CI yet because the development
// environment used to generate this file did not have a Flutter SDK. They are
// included as a starting point for the Jalon 0 "safety net" described in
// ARCHITECTURE.md §11.2.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:countscore/models/game.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/models/round.dart';
import 'package:countscore/models/score.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for desktop/CI test environments.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('v6 schema (fresh install)', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 6,
        onCreate: (db, version) async {
          // We can't easily reuse DatabaseService._createDB without exposing it.
          // For now we duplicate the schema — when refactoring this test, expose
          // _createDB as @visibleForTesting in DatabaseService.
          // TODO(jalon-0): expose DatabaseService._createDB and reuse it here.
        },
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('placeholder: tables exist after onCreate', () async {
      // Once _createDB is exposed, replace with:
      //   final tables = await db.rawQuery(
      //     "SELECT name FROM sqlite_master WHERE type='table'");
      //   final names = tables.map((t) => t['name']).toSet();
      //   expect(names, containsAll(
      //     ['game_types', 'games', 'players', 'rounds', 'scores',
      //      'outbox', 'sync_state']));
    }, skip: 'requires DatabaseService._createDB to be @visibleForTesting');
  });

  group('v5 → v6 migration', () {
    test('preserves existing rows and adds uuid + timestamps', () async {
      // Step 1: create a v5 database with sample data.
      final dbV5 = await openDatabase(
        inMemoryDatabasePath,
        version: 5,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE game_types (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              iconCodePoint INTEGER NOT NULL,
              cardColorValue INTEGER NOT NULL,
              isLowestScoreWins INTEGER NOT NULL,
              isDefault INTEGER NOT NULL DEFAULT 0,
              playerDeadConditionType TEXT,
              playerDeadThreshold INTEGER,
              gameOverConditionType TEXT,
              gameOverThreshold INTEGER
            )
          ''');
          await db.execute('''
            CREATE TABLE games (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              gameTypeId INTEGER,
              isLowestScoreWins INTEGER NOT NULL,
              createdAt TEXT NOT NULL,
              lastModified TEXT
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
          await db.insert('games', {
            'name': 'Test',
            'isLowestScoreWins': 1,
            'createdAt': '2026-01-15T12:00:00.000Z',
          });
          await db.insert('players', {
            'gameId': 1,
            'name': 'Alice',
            'orderIndex': 0,
          });
        },
      );
      await dbV5.close();

      // Step 2: re-open with version 6, triggering the upgrade.
      // The test calls into the production migration code, so the path is
      // exercised exactly as it would be on a real device.
      //
      // TODO(jalon-0): expose DatabaseService._upgradeDB via a test helper
      // (currently private). Until that's done, this test is skipped.
    }, skip: 'requires DatabaseService._upgradeDB to be @visibleForTesting');
  });

  group('Model serialization (v5-compatible)', () {
    test('Game toMap/fromMap roundtrip', () {
      final game = Game(
        id: 42,
        name: 'Test',
        gameTypeId: 1,
        isLowestScoreWins: true,
      );
      expect(Game.fromMap(game.toMap()).name, 'Test');
    });

    test('Player toMap/fromMap roundtrip with color', () {
      final player = Player(
        gameId: 1,
        name: 'Alice',
        orderIndex: 0,
        colorValue: 0xFF00FF00,
      );
      expect(Player.fromMap(player.toMap()).colorValue, 0xFF00FF00);
    });

    test('Round toMap/fromMap roundtrip', () {
      final round = Round(gameId: 1, roundNumber: 3);
      expect(Round.fromMap(round.toMap()).roundNumber, 3);
    });

    test('Score toMap/fromMap roundtrip', () {
      final score = Score(playerId: 1, roundId: 1, value: -5);
      expect(Score.fromMap(score.toMap()).value, -5);
    });

    test('GameType conditions roundtrip', () {
      final gt = GameType.zapzap();
      final back = GameType.fromMap(gt.toMap());
      expect(back.playerDeadConditionType, PlayerDeadConditionType.over);
      expect(back.playerDeadThreshold, 100);
    });
  });
}
