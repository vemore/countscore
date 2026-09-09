// Integration tests for DatabaseService.
//
// Run with: flutter test test/database_service_test.dart
//
// Uses sqflite_common_ffi for in-memory databases (no device required).

import 'package:countscore/models/game.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/models/round.dart';
import 'package:countscore/models/score.dart';
import 'package:countscore/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Build the v9 schema via DatabaseService.createDB (exposed @visibleForTesting).
Future<Database> _openV9() async => openDatabase(
      inMemoryDatabasePath,
      version: 9,
      onCreate: (db, v) => DatabaseService.instance.createDB(db, v),
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() => DatabaseService.debugDatabase = null);
  tearDown(() => DatabaseService.debugDatabase = null);

  // ── v9 fresh-install schema ───────────────────────────────────────────────
  group('v9 schema (fresh install)', () {
    late Database db;

    setUp(() async => db = await _openV9());
    tearDown(() async => db.close());

    test('all required tables exist after onCreate', () async {
      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );
      final names = rows.map((r) => r['name'] as String).toSet();
      expect(
        names,
        containsAll([
          'game_analyses',
          'game_players',
          'game_types',
          'games',
          'outbox',
          'players',
          'rounds',
          'scores',
          'sync_state',
        ]),
      );
    });

    test('default game types seeded', () async {
      final rows = await db.query('game_types', columns: ['name']);
      final names = rows.map((r) => r['name'] as String).toSet();
      expect(names, containsAll(['ZapZap', 'Uno', 'Skyjo']));
    });

    test('CRUD via DatabaseService singleton works on injected DB', () async {
      DatabaseService.debugDatabase = db;

      final gameId = await DatabaseService.instance.createGame(
        Game(name: 'Test Game', isLowestScoreWins: false),
      );
      expect(gameId, greaterThan(0));

      final playerId = await DatabaseService.instance.createPlayer(
        Player(gameId: gameId, name: 'Alice', orderIndex: 0),
      );
      expect(playerId, greaterThan(0));

      final players = await DatabaseService.instance.getPlayersByGame(gameId);
      expect(players.length, 1);
      expect(players.first.name, 'Alice');

      final roundId = await DatabaseService.instance.createRound(
        Round(gameId: gameId, roundNumber: 1),
      );
      await DatabaseService.instance.upsertScore(
        Score(playerId: playerId, roundId: roundId, value: 42),
      );
      final s = await DatabaseService.instance.getScore(playerId, roundId);
      expect(s?.value, 42);
    });
  });

  // ── v8 → v9 migration ────────────────────────────────────────────────────
  group('v8 → v9 migration', () {
    test('global player dedup: same name across games → one global row',
        () async {
      // Build a v8 schema (per-game players)
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 8,
        onCreate: (d, _) async {
          await d.execute('''CREATE TABLE games (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL, gameTypeId INTEGER,
            isLowestScoreWins INTEGER NOT NULL, createdAt TEXT NOT NULL,
            lastModified TEXT,
            uuid TEXT, created_at INTEGER, updated_at INTEGER,
            deleted_at INTEGER, group_id TEXT)''');
          await d.execute('''CREATE TABLE players (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            gameId INTEGER NOT NULL, name TEXT NOT NULL,
            orderIndex INTEGER NOT NULL, colorValue INTEGER,
            uuid TEXT, created_at INTEGER, updated_at INTEGER,
            deleted_at INTEGER, group_id TEXT)''');
          await d.execute('''CREATE INDEX idx_players_gameId ON players(gameId)''');
          await d.execute('''CREATE INDEX idx_players_group_id ON players(group_id)''');
          await d.execute('''CREATE UNIQUE INDEX idx_players_uuid ON players(uuid)''');
          await d.execute('''CREATE TABLE game_types (id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL, iconCodePoint INTEGER NOT NULL,
            cardColorValue INTEGER NOT NULL, isLowestScoreWins INTEGER NOT NULL,
            isDefault INTEGER NOT NULL DEFAULT 0, playerDeadConditionType TEXT,
            playerDeadThreshold INTEGER, gameOverConditionType TEXT,
            gameOverThreshold INTEGER, uuid TEXT, created_at INTEGER,
            updated_at INTEGER, deleted_at INTEGER, group_id TEXT)''');
          await d.execute('''CREATE TABLE rounds (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            gameId INTEGER NOT NULL, roundNumber INTEGER NOT NULL,
            comment TEXT, uuid TEXT, created_at INTEGER,
            updated_at INTEGER, deleted_at INTEGER, group_id TEXT)''');
          await d.execute('''CREATE TABLE scores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            playerId INTEGER NOT NULL, roundId INTEGER NOT NULL,
            value INTEGER NOT NULL, uuid TEXT, created_at INTEGER,
            updated_at INTEGER, deleted_at INTEGER, group_id TEXT)''');
        },
      );

      // Seed data
      final g1 = await db.insert('games', {
        'name': 'G1', 'isLowestScoreWins': 0, 'createdAt': '2026-01-01T00:00:00Z',
        'uuid': 'g1', 'created_at': 0, 'updated_at': 0,
      });
      final g2 = await db.insert('games', {
        'name': 'G2', 'isLowestScoreWins': 0, 'createdAt': '2026-01-02T00:00:00Z',
        'uuid': 'g2', 'created_at': 0, 'updated_at': 0,
      });
      final p1 = await db.insert('players', {
        'gameId': g1, 'name': 'Alice', 'orderIndex': 0,
        'uuid': 'p1', 'created_at': 0, 'updated_at': 0,
      });
      final p2 = await db.insert('players', {
        'gameId': g2, 'name': 'Alice', 'orderIndex': 0,
        'uuid': 'p2', 'created_at': 0, 'updated_at': 0,
      });
      final r1 = await db.insert('rounds', {
        'gameId': g1, 'roundNumber': 1,
        'uuid': 'r1', 'created_at': 0, 'updated_at': 0,
      });
      await db.insert('scores', {
        'playerId': p1, 'roundId': r1, 'value': 10,
        'uuid': 's1', 'created_at': 0, 'updated_at': 0,
      });
      final r2 = await db.insert('rounds', {
        'gameId': g2, 'roundNumber': 1,
        'uuid': 'r2', 'created_at': 0, 'updated_at': 0,
      });
      await db.insert('scores', {
        'playerId': p2, 'roundId': r2, 'value': 5,
        'uuid': 's2', 'created_at': 0, 'updated_at': 0,
      });

      // Run migration.
      await DatabaseService.instance.upgradeV8toV9(db);

      // One global player "Alice".
      final globals = await db.query('players', columns: ['name']);
      expect(globals.where((r) => r['name'] == 'Alice').length, 1);

      // Two game_players rows (one per game).
      final gps = await db.query('game_players');
      expect(gps.length, 2);
      expect(gps.every((gp) => gp['player_id'] != null), isTrue);

      // Scores untouched.
      final scores = await db.query('scores');
      expect(scores.length, 2);

      // Stats work correctly.
      DatabaseService.debugDatabase = db;
      final stats = await DatabaseService.instance.getPlayerStats('Alice');
      expect(stats['gamesPlayed'], 2);

      await db.close();
    });
  });

  // ── Model serialization ───────────────────────────────────────────────────
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
