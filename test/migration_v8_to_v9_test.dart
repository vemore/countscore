import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:countscore/services/database_service.dart';

/// Builds the pre-v9 (per-game players) schema so we can exercise the
/// v8 → v9 global-player migration (`DatabaseService.upgradeV8toV9`).
Future<void> _createV8Schema(Database db, int version) async {
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
      gameOverThreshold INTEGER,
      uuid TEXT, created_at INTEGER, updated_at INTEGER, deleted_at INTEGER, group_id TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE games (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      gameTypeId INTEGER,
      isLowestScoreWins INTEGER NOT NULL,
      createdAt TEXT NOT NULL,
      lastModified TEXT,
      uuid TEXT, created_at INTEGER, updated_at INTEGER, deleted_at INTEGER, group_id TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE players (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      gameId INTEGER NOT NULL,
      name TEXT NOT NULL,
      orderIndex INTEGER NOT NULL,
      colorValue INTEGER,
      uuid TEXT, created_at INTEGER, updated_at INTEGER, deleted_at INTEGER, group_id TEXT,
      FOREIGN KEY (gameId) REFERENCES games (id) ON DELETE CASCADE
    )
  ''');
  await db.execute('''
    CREATE TABLE rounds (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      gameId INTEGER NOT NULL,
      roundNumber INTEGER NOT NULL,
      comment TEXT,
      uuid TEXT, created_at INTEGER, updated_at INTEGER, deleted_at INTEGER, group_id TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE scores (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      playerId INTEGER NOT NULL,
      roundId INTEGER NOT NULL,
      value INTEGER NOT NULL,
      uuid TEXT, created_at INTEGER, updated_at INTEGER, deleted_at INTEGER, group_id TEXT,
      FOREIGN KEY (playerId) REFERENCES players (id) ON DELETE CASCADE
    )
  ''');
  await db.execute('CREATE INDEX idx_players_gameId ON players(gameId)');
  await db.execute('CREATE INDEX idx_players_group_id ON players(group_id)');
  await db.execute('CREATE UNIQUE INDEX idx_players_uuid ON players(uuid)');
}

Future<int> _addGame(Database db, String name, {bool lowestWins = false}) {
  return db.insert('games', {
    'name': name,
    'gameTypeId': 1,
    'isLowestScoreWins': lowestWins ? 1 : 0,
    'createdAt': DateTime.now().toIso8601String(),
    'uuid': 'g-$name-${DateTime.now().microsecondsSinceEpoch}',
    'created_at': 0,
    'updated_at': 0,
  });
}

Future<int> _addPlayer(Database db, int gameId, String name, int order) {
  return db.insert('players', {
    'gameId': gameId,
    'name': name,
    'orderIndex': order,
    'colorValue': 0xFF0000FF,
    'uuid': 'p-$gameId-$name-$order',
    'created_at': 0,
    'updated_at': 0,
  });
}

Future<int> _addRound(Database db, int gameId, int number) {
  return db.insert('rounds', {
    'gameId': gameId,
    'roundNumber': number,
    'uuid': 'r-$gameId-$number',
    'created_at': 0,
    'updated_at': 0,
  });
}

Future<void> _addScore(Database db, int playerId, int roundId, int value) async {
  await db.insert('scores', {
    'playerId': playerId,
    'roundId': roundId,
    'value': value,
    'uuid': 's-$playerId-$roundId',
    'created_at': 0,
    'updated_at': 0,
  });
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() {
    DatabaseService.debugDatabase = null;
  });
  tearDown(() {
    DatabaseService.debugDatabase = null;
  });

  test('dedup across games: same name = one global player, scores preserved',
      () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 8, onCreate: _createV8Schema),
    );
    await db.insert('game_types', {
      'id': 1,
      'name': 'Cards',
      'iconCodePoint': 0,
      'cardColorValue': 0,
      'isLowestScoreWins': 0,
    });

    // Game 1: Alice beats Bob.
    final g1 = await _addGame(db, 'G1');
    final a1 = await _addPlayer(db, g1, 'Alice', 0);
    final b1 = await _addPlayer(db, g1, 'Bob', 1);
    final r1 = await _addRound(db, g1, 1);
    await _addScore(db, a1, r1, 10);
    await _addScore(db, b1, r1, 5);

    // Game 2: Charlie beats Alice.
    final g2 = await _addGame(db, 'G2');
    final a2 = await _addPlayer(db, g2, 'Alice', 0);
    final c2 = await _addPlayer(db, g2, 'Charlie', 1);
    final r2 = await _addRound(db, g2, 1);
    await _addScore(db, a2, r2, 3);
    await _addScore(db, c2, r2, 8);

    final scoresBefore =
        await db.rawQuery('SELECT COUNT(*) as c FROM scores');

    await DatabaseService.instance.upgradeV8toV9(db);

    // Global players deduped by name.
    final names = (await db.query('players', columns: ['name'], orderBy: 'name'))
        .map((r) => r['name'] as String)
        .toList();
    expect(names, ['Alice', 'Bob', 'Charlie']);

    // Memberships preserved, all linked to a global player.
    final gp = await db.query('game_players');
    expect(gp.length, 4);
    expect(gp.every((m) => m['player_id'] != null), isTrue);

    // Scores untouched.
    final scoresAfter = await db.rawQuery('SELECT COUNT(*) as c FROM scores');
    expect(scoresAfter.first['c'], scoresBefore.first['c']);

    // Stats now key by global identity, not name aggregation.
    DatabaseService.debugDatabase = db;
    final aliceStats = await DatabaseService.instance.getPlayerStats('Alice');
    expect(aliceStats['gamesPlayed'], 2);
    expect(aliceStats['wins'], 1); // won G1, lost G2

    final allNames = await DatabaseService.instance.getAllPlayerNames();
    expect(allNames, containsAll(['Alice', 'Bob', 'Charlie']));

    await db.close();
  });

  test('same name within one game stays distinct (suffixed global)', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 8, onCreate: _createV8Schema),
    );
    await db.insert('game_types', {
      'id': 1,
      'name': 'Cards',
      'iconCodePoint': 0,
      'cardColorValue': 0,
      'isLowestScoreWins': 0,
    });

    final g = await _addGame(db, 'Doubles');
    final alice1 = await _addPlayer(db, g, 'Alice', 0);
    final alice2 = await _addPlayer(db, g, 'Alice', 1);
    final r = await _addRound(db, g, 1);
    await _addScore(db, alice1, r, 12);
    await _addScore(db, alice2, r, 7);

    await DatabaseService.instance.upgradeV8toV9(db);

    final names = (await db.query('players', columns: ['name'], orderBy: 'name'))
        .map((r) => r['name'] as String)
        .toList();
    expect(names, ['Alice', 'Alice (2)']);

    // The two memberships point at two distinct global players.
    final gp = await db.query('game_players', orderBy: 'orderIndex');
    expect(gp.length, 2);
    expect(gp[0]['player_id'] != gp[1]['player_id'], isTrue);
    // In-game display name is preserved for both.
    expect(gp.map((m) => m['name']).toList(), ['Alice', 'Alice']);

    await db.close();
  });
}
