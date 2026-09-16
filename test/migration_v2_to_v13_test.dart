// The oldest shapes still in the chain: a v2 and a v4 database, upgraded through
// the production callbacks all the way to the current version.
//
// Nothing else in the suite starts below v5, and that gap hid a real defect: the
// v4 → v5 step and the v2 → v3 step both **seed** game types, and a seed writes
// `GameType.toMap()` against a table that is eight versions younger than the
// model. sqflite builds its INSERT column list from the map keys, so one key too
// many is `SqliteException(1): table game_types has no column named …`, thrown
// inside `onUpgrade` — the open fails and the database is unopenable for good.
//
// These fixtures upgrade a device that is *missing* seeded types, because the two
// steps only insert what is absent. A device holding all ten never reaches the
// failing INSERT at all, which is why the defect was invisible.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:countscore/models/game_type.dart';
import 'package:countscore/services/database_service.dart';

/// The schema at v2 and v4, the two shapes these tests start from.
///
/// At **v2** there is no `game_types` table at all: `games.gameType` holds a name.
/// The v2 → v3 step creates the six-column table and seeds it — that is the seed
/// that predates the condition columns.
/// At **v4** `game_types` has the six columns plus nothing else; the v4 → v5 step
/// adds the four condition columns and re-seeds whatever is missing.
Future<void> _createOldSchema(Database db, int version) async {
  if (version >= 3) {
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
  }
  await db.execute('''
    CREATE TABLE games (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      gameType TEXT NOT NULL DEFAULT 'ZapZap',
      isLowestScoreWins INTEGER NOT NULL,
      createdAt TEXT NOT NULL,
      lastModified TEXT${version >= 3 ? ',\n      gameTypeId INTEGER' : ''}
    )
  ''');
  await db.execute('''
    CREATE TABLE players (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      gameId INTEGER NOT NULL,
      name TEXT NOT NULL,
      orderIndex INTEGER NOT NULL${version >= 4 ? ',\n      colorValue INTEGER' : ''}
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
    dir = await Directory.systemTemp.createTemp('countscore_old_');
    path = '${dir.path}/countscore.db';
  });
  tearDown(() => dir.delete(recursive: true));

  /// Builds an old database holding only the game types named, then runs the
  /// production chain over it.
  Future<Database> upgradeFrom(int version, List<String> typeNames) async {
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: (db, v) => _createOldSchema(db, version),
      ),
    );
    await old.insert('games', {
      'name': 'Mardi',
      'gameType': 'ZapZap',
      'isLowestScoreWins': 1,
      'createdAt': '2026-01-01T00:00:00.000',
    });
    for (final name in typeNames) {
      await old.insert('game_types', {
        'name': name,
        'iconCodePoint': 0xe000,
        'cardColorValue': 0xFF000000,
        'isLowestScoreWins': 0,
        'isDefault': 1,
      });
    }
    await old.close();
    final db = await DatabaseService.instance.openForTesting(path);
    addTearDown(db.close);
    return db;
  }

  test('a v4 device missing six seeded types upgrades instead of failing to open',
      () async {
    // This is the regression. The v4 → v5 step inserts Skyjo, Président, Belote,
    // Tarot, Bridge and Rami when they are absent, and each insert wrote a
    // `builtin_key` the table would not carry for another eight versions.
    final db = await upgradeFrom(4, ['ZapZap', 'Uno', 'Scrabble', 'Autre']);

    expect(await db.getVersion(), DatabaseService.schemaVersion);

    final rows = await db.query('game_types', columns: ['name', 'builtin_key']);
    final names = rows.map((r) => r['name'] as String).toSet();
    // The six the v5 step re-seeds, then the twelve v13 adds.
    expect(names, containsAll(['Skyjo', 'Président', 'Belote', 'Tarot', 'Bridge', 'Rami']));
    expect(names, containsAll(['Yahtzee', 'Coinche', 'Triomino']));
    // v5 gave the re-seeded types their thresholds, and v13 gave every one of
    // the 22 its key.
    expect(rows.map((r) => r['builtin_key']).whereType<String>(), hasLength(22));

    final skyjo = await db.query('game_types', where: 'name = ?', whereArgs: ['Skyjo']);
    expect(skyjo.single['gameOverThreshold'], 100);
    expect(skyjo.single['builtin_key'], 'skyjo');
  });

  test('a v2 device upgrades too — that seed predates the condition columns', () async {
    // The v2 → v3 step creates the six-column table and seeds all 22 types into
    // it. `toMap()` carries four condition columns v3 does not have, and now
    // `builtin_key` on top — the same class of defect, one step earlier. It was
    // already broken on `main` for the condition columns; the column filter in
    // `_gameTypeRow` covers both at once.
    final db = await upgradeFrom(2, const []);

    expect(await db.getVersion(), DatabaseService.schemaVersion);
    final rows = await db.query('game_types', columns: ['name', 'builtin_key']);
    expect(rows, hasLength(22));
    expect(
      rows.map((r) => r['builtin_key']).toSet(),
      GameType.defaultGameTypes().map((t) => t.builtinKey).toSet(),
    );
    // v5 then filled in the conditions the v3 seed could not carry.
    final zapzap = await db.query('game_types', where: 'name = ?', whereArgs: ['ZapZap']);
    expect(zapzap.single['playerDeadThreshold'], 100);
    // And the v4 step matched `games.gameType` to the seeded row.
    final game = await db.query('games', columns: ['gameTypeId']);
    expect(game.single['gameTypeId'], isNotNull);
  });

  test('a v4 device that kept every seeded type gains no duplicate', () async {
    final db = await upgradeFrom(4, GameType.seededNamesBeforeV13.values.toList());

    final rows = await db.query('game_types', columns: ['name', 'builtin_key']);
    expect(rows, hasLength(22));
    expect(rows.map((r) => r['builtin_key']).toSet(), hasLength(22));
  });
}
