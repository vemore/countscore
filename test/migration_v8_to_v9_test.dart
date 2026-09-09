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

/// Builds the schema of a database that reached `user_version = 8` while its
/// tables still had the **pre-v6** shape: no sync columns
/// (`uuid` / `created_at` / `updated_at` / `deleted_at` / `group_id`) and no
/// `outbox` / `sync_state` tables. Real installs in the wild are in this state
/// — the version counter moved on without the v5 → v6 step ever landing.
///
/// Reproduced from an actual device database (64 games, 339 players): its
/// `players` table was exactly `id, gameId, name, orderIndex, colorValue`.
/// On such a database the v8 → v9 step used to die with
/// `no such column: uuid` while creating `idx_game_players_uuid`, which left
/// the app unable to open its own data at all.
Future<void> _createStampedV8ButPreV6Schema(Database db, int version) async {
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
      isLowestScoreWins INTEGER NOT NULL,
      createdAt TEXT NOT NULL,
      lastModified TEXT,
      gameType TEXT,
      gameTypeId INTEGER
    )
  ''');
  await db.execute('''
    CREATE TABLE players (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      gameId INTEGER NOT NULL,
      name TEXT NOT NULL,
      orderIndex INTEGER NOT NULL,
      colorValue INTEGER,
      FOREIGN KEY (gameId) REFERENCES games (id) ON DELETE CASCADE
    )
  ''');
  // `comment` is present: that half of the v5 → v6 step did land.
  await db.execute('''
    CREATE TABLE rounds (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      gameId INTEGER NOT NULL,
      roundNumber INTEGER NOT NULL,
      comment TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE scores (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      playerId INTEGER NOT NULL,
      roundId INTEGER NOT NULL,
      value INTEGER NOT NULL,
      FOREIGN KEY (playerId) REFERENCES players (id) ON DELETE CASCADE
    )
  ''');
  await db.execute('CREATE INDEX idx_players_gameId ON players(gameId)');
  await db.execute('CREATE INDEX idx_rounds_gameId ON rounds(gameId)');
  await db.execute('CREATE INDEX idx_scores_playerId ON scores(playerId)');
}

Future<int> _addLegacyGame(Database db, String name) {
  return db.insert('games', {
    'name': name,
    'gameTypeId': 1,
    'isLowestScoreWins': 0,
    'createdAt': DateTime.now().toIso8601String(),
  });
}

Future<int> _addLegacyPlayer(Database db, int gameId, String name, int order) {
  return db.insert('players', {
    'gameId': gameId,
    'name': name,
    'orderIndex': order,
    'colorValue': 0xFF00FF00,
  });
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

  test('database stamped v8 with a pre-v6 schema still migrates', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 8,
        onCreate: _createStampedV8ButPreV6Schema,
      ),
    );

    await db.insert('game_types', {
      'id': 1,
      'name': 'Cards',
      'iconCodePoint': 0,
      'cardColorValue': 0,
      'isLowestScoreWins': 0,
    });

    final g1 = await _addLegacyGame(db, 'Tarot');
    final g2 = await _addLegacyGame(db, 'Belote');
    final alice1 = await _addLegacyPlayer(db, g1, 'Alice', 0);
    final bob = await _addLegacyPlayer(db, g1, 'Bob', 1);
    final alice2 = await _addLegacyPlayer(db, g2, 'alice', 0);
    final r1 = await db.insert('rounds', {'gameId': g1, 'roundNumber': 1});
    await db.insert('scores', {'playerId': alice1, 'roundId': r1, 'value': 12});
    await db.insert('scores', {'playerId': bob, 'roundId': r1, 'value': 7});
    final r2 = await db.insert('rounds', {'gameId': g2, 'roundNumber': 1});
    await db.insert('scores', {'playerId': alice2, 'roundId': r2, 'value': 30});

    // This is the call that used to throw `no such column: uuid`.
    await DatabaseService.instance.upgradeV8toV9(db);

    // The missing v6 shape was repaired on the way through.
    final playerColumns = (await db.rawQuery('PRAGMA table_info(players)'))
        .map((r) => r['name'] as String)
        .toSet();
    expect(
      playerColumns,
      containsAll(['uuid', 'created_at', 'updated_at', 'deleted_at', 'group_id']),
    );
    final tables = (await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    ))
        .map((r) => r['name'] as String)
        .toSet();
    expect(tables, containsAll(['outbox', 'sync_state', 'game_players']));

    // Every row got a uuid backfilled, and they are unique.
    final uuids = (await db.query('players', columns: ['uuid']))
        .map((r) => r['uuid'] as String?)
        .toList();
    expect(uuids.any((u) => u == null), isFalse);
    expect(uuids.toSet().length, uuids.length);

    // And the v9 dedup still happened: Alice/alice collapse across games.
    final names = (await db.query('players', columns: ['name'], orderBy: 'name'))
        .map((r) => r['name'] as String)
        .toList();
    expect(names, ['Alice', 'Bob']);

    // No score was lost.
    final scoreCount =
        (await db.rawQuery('SELECT COUNT(*) AS n FROM scores')).single['n'];
    expect(scoreCount, 3);

    await db.close();
  });

  test('replaying the v6 repair on an already-migrated database is a no-op',
      () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 8,
        onCreate: _createStampedV8ButPreV6Schema,
      ),
    );
    final g = await _addLegacyGame(db, 'Tarot');
    await _addLegacyPlayer(db, g, 'Alice', 0);

    await DatabaseService.instance.upgradeV8toV9(db);
    final uuidBefore =
        (await db.query('players', columns: ['uuid'])).single['uuid'] as String;

    // A second pass must neither throw nor churn the backfilled uuids.
    await DatabaseService.instance.ensureV6ShapeForTesting(db);
    final uuidAfter =
        (await db.query('players', columns: ['uuid'])).single['uuid'] as String;
    expect(uuidAfter, uuidBefore);

    await db.close();
  });
}
