// The upgrade a Play Store user actually takes: the 1.0.1 release shipped schema
// v5 on sqflite, and the next release runs v5 → v10 on that file before Drift
// adopts it. Nothing else in the suite starts from a real v5 file — the v8
// fixtures in migration_v8_to_v9_test.dart are hand-built intermediate shapes.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:countscore/models/game.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/models/round.dart';
import 'package:countscore/models/score.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/database_service.dart';
import 'package:countscore/services/drift/database.dart';

/// `_createDB` as of tag `1.0.1+3`, verbatim DDL, minus the default game types
/// (inserted by the test so their ids are known).
Future<void> _createV5Schema(Database db, int version) async {
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
      lastModified TEXT,
      FOREIGN KEY (gameTypeId) REFERENCES game_types (id) ON DELETE SET NULL
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
  await db.execute('''
    CREATE TABLE rounds (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      gameId INTEGER NOT NULL,
      roundNumber INTEGER NOT NULL,
      FOREIGN KEY (gameId) REFERENCES games (id) ON DELETE CASCADE
    )
  ''');
  await db.execute('''
    CREATE TABLE scores (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      playerId INTEGER NOT NULL,
      roundId INTEGER NOT NULL,
      value INTEGER NOT NULL,
      FOREIGN KEY (playerId) REFERENCES players (id) ON DELETE CASCADE,
      FOREIGN KEY (roundId) REFERENCES rounds (id) ON DELETE CASCADE
    )
  ''');
  await db.execute('CREATE INDEX idx_games_gameTypeId ON games(gameTypeId)');
  await db.execute('CREATE INDEX idx_players_gameId ON players(gameId)');
  await db.execute('CREATE INDEX idx_rounds_gameId ON rounds(gameId)');
  await db.execute('CREATE INDEX idx_scores_playerId ON scores(playerId)');
  await db.execute('CREATE INDEX idx_scores_roundId ON scores(roundId)');
}

/// A v5 install with two finished games sharing a player, as 1.0.1 wrote them.
Future<void> _seedV5(String path) async {
  final db = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(version: 5, onCreate: _createV5Schema),
  );
  await db.insert('game_types', {
    'id': 1,
    'name': 'ZapZap',
    'iconCodePoint': 0xe000,
    'cardColorValue': 0xFFFFC107,
    'isLowestScoreWins': 1,
    'isDefault': 1,
    'playerDeadConditionType': 'over',
    'playerDeadThreshold': 100,
  });

  Future<void> game(String name, String createdAt, Map<String, int> totals) async {
    final gameId = await db.insert('games', {
      'name': name,
      'gameTypeId': 1,
      'isLowestScoreWins': 1,
      'createdAt': createdAt,
    });
    final roundId = await db.insert('rounds', {'gameId': gameId, 'roundNumber': 1});
    var order = 0;
    for (final e in totals.entries) {
      final playerId = await db.insert('players', {
        'gameId': gameId,
        'name': e.key,
        'orderIndex': order++,
        'colorValue': 0xFF2196F3,
      });
      await db.insert('scores', {'playerId': playerId, 'roundId': roundId, 'value': e.value});
    }
  }

  await game('Mardi', '2025-11-18T20:00:00.000', {'Alice': 12, 'Bob': 30});
  await game('Jeudi', '2025-11-20T21:00:00.000', {'alice': 40, 'Chloé': 8});
  await db.close();
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('countscore_v5_');
    path = '${dir.path}/countscore.db';
    DatabaseService.debugDatabase = null;
  });

  tearDown(() async {
    DatabaseService.debugDatabase = null;
    await dir.delete(recursive: true);
  });

  test('a 1.0.1 database upgrades to v10 and Drift reads every game back', () async {
    await _seedV5(path);

    final sqflite = await DatabaseService.instance.openForTesting(path);
    expect(await sqflite.getVersion(), DatabaseService.schemaVersion);
    final tables = (await sqflite.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    ))
        .map((r) => r['name'] as String)
        .toSet();
    expect(
      tables,
      containsAll([
        'game_players', 'outbox', 'sync_state', 'game_analyses', //
        'group_links', 'entity_versions', 'sync_inbox',
      ]),
    );
    await sqflite.close();

    // What connection_native.dart does next: Drift adopts the migrated file.
    final db = AppDatabase.forTesting(NativeDatabase(File(path)));
    addTearDown(db.close);

    final games = await DriftGameRepository(db).getAll();
    expect(games.map((g) => g.name), ['Jeudi', 'Mardi']);
    expect(games.every((g) => g.gameTypeId == 1), isTrue);
    // v13: this fixture holds one type, ZapZap. It is back-filled in place —
    // same row, same id, so the games still point at it — and the twelve types
    // the seed never held arrive alongside it. The nine other pre-v13 types
    // were never in this database and are *not* resurrected: 1 + 12 = 13.
    final types = await DriftGameTypeRepository(db).getAll();
    expect(types.where((t) => t.builtinKey == 'zapzap').map((t) => t.id), [1]);
    expect(types, hasLength(13));
    expect(types.every((t) => t.builtinKey != null), isTrue);
    expect(types.map((t) => t.builtinKey), contains('mille_bornes'));
    expect(types.map((t) => t.builtinKey), isNot(contains('skyjo')));
    expect(games.every((g) => g.isFinished), isFalse,
        reason: 'v12 adds finishedAt as null; no existing game becomes finished');

    final players = DriftPlayerRepository(db);
    expect(await players.getAllNames(), ['Alice', 'Bob', 'Chloé']);
    final mardi = games.last;
    final mardiPlayers = await players.getByGame(mardi.id!);
    expect(mardiPlayers.map((p) => p.name), ['Alice', 'Bob']);

    final rounds = await DriftRoundRepository(db).getByGame(mardi.id!);
    expect(rounds.single.roundNumber, 1);
    expect(rounds.single.comment, isNull);
    final aliceScore = await DriftScoreRepository(db)
        .getByPlayerAndRound(mardiPlayers.first.id!, rounds.single.id!);
    expect(aliceScore?.value, 12);

    // Alice and alice are one human now; lowest score wins, so she won Mardi only.
    final stats = await DriftPlayerStatsRepository(db).getStatsByName('Alice');
    expect(stats['gamesPlayed'], 2);
    expect(stats['wins'], 1);

    // Nothing upgraded belongs to a group, and the app can write to the file.
    final shared = await db
        .customSelect('SELECT COUNT(*) AS c FROM games WHERE group_id IS NOT NULL')
        .getSingle();
    expect(shared.data['c'], 0);
    final newGame = await DriftGameRepository(db)
        .create(Game(name: 'Après migration', isLowestScoreWins: true, gameTypeId: 1));
    final p = await players.create(Player(gameId: newGame, name: 'Bob', orderIndex: 0));
    final r = await DriftRoundRepository(db).create(Round(gameId: newGame, roundNumber: 1));
    await DriftScoreRepository(db).create(Score(playerId: p, roundId: r, value: 3));
    expect((await DriftPlayerStatsRepository(db).getStatsByName('Bob'))['gamesPlayed'], 2);

    // The v12 column is writable on a file that came all the way from v5.
    final at = DateTime(2026, 9, 16, 21);
    await DriftGameRepository(db)
        .update((await DriftGameRepository(db).getById(newGame))!
            .copyWith(finishedAt: at));
    expect((await DriftGameRepository(db).getById(newGame))?.finishedAt, at);
  });

  test('reopening an upgraded file is a no-op', () async {
    await _seedV5(path);
    await (await DatabaseService.instance.openForTesting(path)).close();

    final again = await DatabaseService.instance.openForTesting(path);
    final games = await again.rawQuery('SELECT COUNT(*) AS c FROM games');
    expect(games.single['c'], 2);
    await again.close();
  });
}
