// The fictional demo database the store screenshots are taken on.
//
// Six invented first names, ten games under place names, one custom
// game type. Nothing in it is a real person's data: the store images must never
// show one (.llmwiki/StoreListing.md).
//
// Built the way an Android install builds its own file — the sqflite chain
// creates and seeds the current schema, then Drift adopts the file and the
// repositories the app uses write every row — so what comes out is a
// `countscore.db` that Settings → Import accepts as is.
//
// Write one with:
//   DEMO_DB_OUT=/tmp/countscore_demo.db flutter test test/demo_db_test.dart

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:countscore/models/game.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/models/round.dart';
import 'package:countscore/models/score.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/services/database_service.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/utils/player_colors.dart';

/// The demo players, each with the palette colour they keep in every game.
const Map<String, int> kDemoPlayers = {
  'Emma': 0xFFE4572E,
  'Léo': 0xFF3B82F6,
  'Sofia': 0xFF10B981,
  'Noah': 0xFFA855F7,
  'Maya': 0xFFF59E0B,
  'Hugo': 0xFFEC4899,
};

/// The custom game type (a garden game, no trademark).
const String kDemoCustomTypeName = 'Kubb';

/// One demo game: [rounds] lists each round's scores in [players] order.
class DemoGame {
  const DemoGame({
    required this.name,
    required this.typeKey,
    required this.daysAgo,
    required this.players,
    required this.rounds,
    required this.finished,
  });

  final String name;

  /// A built-in `builtin_key`, or null for [kDemoCustomTypeName].
  final String? typeKey;
  final int daysAgo;
  final List<String> players;
  final List<List<int>> rounds;
  final bool finished;
}

/// Tarot, five players: the taker scores 2x, the called partner x, each of the
/// three defenders -x — every round sums to zero, as on a real sheet.
List<int> _tarot5(List<String> seats, String taker, String partner, int x) => [
      for (final p in seats)
        p == taker
            ? 2 * x
            : p == partner
                ? x
                : -x,
    ];

const _tarotSeats = ['Emma', 'Léo', 'Sofia', 'Noah', 'Maya'];

final List<DemoGame> kDemoGames = [
  // In progress: six rounds, Emma far ahead (lowest total wins at ZapZap).
  const DemoGame(
    name: 'Annecy',
    typeKey: 'zapzap',
    daysAgo: 0,
    players: ['Emma', 'Léo', 'Sofia', 'Noah'],
    rounds: [
      [4, 12, 7, 0],
      [0, 9, 15, 6],
      [3, 0, 11, 14],
      [5, 18, 0, 9],
      [0, 7, 12, 21],
      [2, 13, 8, 0],
    ],
    finished: false,
  ),
  DemoGame(
    name: 'Kyoto',
    typeKey: 'tarot',
    daysAgo: 2,
    players: _tarotSeats,
    rounds: [
      _tarot5(_tarotSeats, 'Maya', 'Léo', 35),
      _tarot5(_tarotSeats, 'Sofia', 'Emma', 40),
      _tarot5(_tarotSeats, 'Maya', 'Noah', 50),
      _tarot5(_tarotSeats, 'Léo', 'Sofia', 30),
      _tarot5(_tarotSeats, 'Noah', 'Maya', 45),
      _tarot5(_tarotSeats, 'Emma', 'Léo', 45),
      _tarot5(_tarotSeats, 'Maya', 'Sofia', 40),
      _tarot5(_tarotSeats, 'Léo', 'Noah', 25),
    ],
    finished: true,
  ),
  // Sofia passes 100 in round 4: the game ends, Hugo has the lowest total.
  const DemoGame(
    name: 'Lisboa',
    typeKey: 'skyjo',
    daysAgo: 4,
    players: ['Léo', 'Maya', 'Hugo', 'Sofia'],
    rounds: [
      [12, 25, 8, 30],
      [18, 22, 5, 27],
      [9, 31, 14, 21],
      [20, 15, 3, 26],
    ],
    finished: true,
  ),
  // 162 points a deal; Noah passes 1000.
  const DemoGame(
    name: 'Oslo',
    typeKey: 'belote',
    daysAgo: 7,
    players: ['Noah', 'Hugo'],
    rounds: [
      [102, 60],
      [40, 122],
      [162, 0],
      [91, 71],
      [20, 142],
      [110, 52],
      [81, 81],
      [130, 32],
      [152, 10],
      [120, 42],
      [100, 62],
    ],
    finished: true,
  ),
  const DemoGame(
    name: 'Porto',
    typeKey: 'yahtzee',
    daysAgo: 10,
    players: ['Maya', 'Hugo', 'Emma'],
    rounds: [
      [243, 198, 221],
    ],
    finished: true,
  ),
  // The custom type: first to 50, highest wins.
  const DemoGame(
    name: 'Sevilla',
    typeKey: null,
    daysAgo: 12,
    players: ['Léo', 'Noah', 'Hugo', 'Sofia'],
    rounds: [
      [12, 8, 10, 5],
      [9, 11, 7, 12],
      [14, 6, 12, 9],
      [10, 13, 11, 8],
      [8, 9, 12, 10],
    ],
    finished: true,
  ),
  // Maya passes 100: Hugo wins by two points.
  const DemoGame(
    name: 'Berlin',
    typeKey: 'zapzap',
    daysAgo: 15,
    players: ['Emma', 'Sofia', 'Hugo', 'Maya'],
    rounds: [
      [5, 14, 0, 20],
      [11, 0, 9, 17],
      [0, 22, 13, 8],
      [7, 9, 0, 25],
      [0, 16, 12, 19],
      [13, 5, 0, 14],
    ],
    finished: true,
  ),
  // Three older games, so every player has the five finished games the
  // statistics screen needs before it ranks them.
  const DemoGame(
    name: 'Nantes',
    typeKey: 'skyjo',
    daysAgo: 20,
    players: ['Emma', 'Léo', 'Noah', 'Maya'],
    rounds: [
      [5, 18, 22, 14],
      [11, 9, 27, 20],
      [3, 24, 19, 30],
      [8, 15, 33, 21],
    ],
    finished: true,
  ),
  const DemoGame(
    name: 'Bergen',
    typeKey: 'yahtzee',
    daysAgo: 24,
    players: ['Emma', 'Léo', 'Noah', 'Sofia'],
    rounds: [
      [212, 187, 256, 231],
    ],
    finished: true,
  ),
  const DemoGame(
    name: 'Riga',
    typeKey: 'zapzap',
    daysAgo: 30,
    players: ['Maya', 'Sofia', 'Hugo'],
    rounds: [
      [0, 12, 9],
      [7, 0, 16],
      [3, 14, 0],
      [0, 22, 11],
      [9, 6, 25],
      [2, 17, 30],
    ],
    finished: true,
  ),
];

/// Writes the demo database to [path] (which must not exist yet), with every
/// game dated relative to [now].
Future<void> writeDemoDatabase(String path, {DateTime? now}) async {
  final at = now ?? DateTime.now();
  if (File(path).existsSync()) {
    throw StateError('$path exists; the demo database is written fresh');
  }

  // 1. The Android bootstrap: the sqflite chain creates and seeds the schema.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final legacy = await DatabaseService.instance.openForTesting(path);
  await legacy.close();

  // 2. Drift adopts the file, and the app's own repositories write the rows.
  final db = AppDatabase.forTesting(NativeDatabase(File(path)));
  try {
    final types = DriftGameTypeRepository(db);
    final games = DriftGameRepository(db);
    final players = DriftPlayerRepository(db);
    final rounds = DriftRoundRepository(db);
    final scores = DriftScoreRepository(db);

    final byKey = {
      for (final t in await types.getAll())
        if (t.builtinKey != null) t.builtinKey!: t,
    };
    final customId = await types.create(GameType(
      name: kDemoCustomTypeName,
      iconCodePoint: Icons.emoji_events.codePoint,
      cardColorValue: kPlayerPalette[4].toARGB32(),
      isLowestScoreWins: false,
      gameOverConditionType: GameOverConditionType.firstPlayerOver,
      gameOverThreshold: 50,
    ));

    // Oldest first, so ids grow with dates as they do on a real phone.
    final ordered = [...kDemoGames]
      ..sort((a, b) => b.daysAgo.compareTo(a.daysAgo));
    for (final demo in ordered) {
      final type = demo.typeKey == null ? null : byKey[demo.typeKey]!;
      final created = at
          .subtract(Duration(days: demo.daysAgo))
          .subtract(const Duration(hours: 2));
      final last = created.add(Duration(minutes: 6 * demo.rounds.length));
      final gameId = await games.create(Game(
        name: demo.name,
        gameTypeId: type?.id ?? customId,
        isLowestScoreWins: type?.isLowestScoreWins ?? false,
        createdAt: created,
        lastModified: last,
        finishedAt: demo.finished ? last : null,
      ));

      final seatIds = <int>[];
      for (var i = 0; i < demo.players.length; i++) {
        final name = demo.players[i];
        seatIds.add(await players.create(Player(
          gameId: gameId,
          name: name,
          orderIndex: i,
          colorValue: kDemoPlayers[name],
        )));
      }

      for (var r = 0; r < demo.rounds.length; r++) {
        final roundId =
            await rounds.create(Round(gameId: gameId, roundNumber: r + 1));
        for (var s = 0; s < seatIds.length; s++) {
          await scores.create(Score(
            playerId: seatIds[s],
            roundId: roundId,
            value: demo.rounds[r][s],
          ));
        }
      }
    }

    // One file, no -wal beside it: Import copies countscore.db alone.
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
  } finally {
    await db.close();
  }
}
