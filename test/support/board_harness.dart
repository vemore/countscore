// A game board over an in-memory database, for the widget tests that open one
// and drive it through the keypad.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game_analysis.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/repositories/game_analysis_repository.dart';
import 'package:countscore/screens/game_board_screen.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/game_sounds.dart';

import 'fake_sound_player.dart';

/// The board asks on open whether this game has a stored analysis; the default
/// reaches the real database.
class NoAnalysis implements GameAnalysisRepository {
  @override
  Future<GameAnalysis?> getByGame(int gameId) async => null;

  @override
  Future<int> upsert(GameAnalysis analysis) async => 0;

  @override
  Future<int> deleteByGame(int gameId) async => 0;

  @override
  Future<List<Map<String, dynamic>>> getRecentPlayerHistory(
    String playerName, {
    int limit = 10,
    int? excludeGameId,
  }) async =>
      const [];
}

/// One board: build it in `setUp`, [close] it in `tearDown`.
class BoardHarness {
  BoardHarness() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    games = GameProvider(
      gameRepo: DriftGameRepository(db),
      playerRepo: DriftPlayerRepository(db),
      roundRepo: DriftRoundRepository(db),
      scoreRepo: DriftScoreRepository(db),
      gameTypeRepo: DriftGameTypeRepository(db),
      statsRepo: DriftPlayerStatsRepository(db),
    );
    gameTypes = GameTypeProvider(repo: DriftGameTypeRepository(db));
  }

  late final AppDatabase db;
  late final GameProvider games;
  late final GameTypeProvider gameTypes;
  final FakeSoundPlayer sounds = FakeSoundPlayer();

  Future<void> close() => db.close();

  /// A type that puts a player out over [eliminatesOver] and/or ends the game
  /// once a player reaches [overAt] — or, with [lastStanding], once every
  /// player but one is over [overAt].
  Future<int> aType(
      {int? eliminatesOver, int? overAt, bool lastStanding = false}) {
    return gameTypes.createGameType(GameType(
      name: 'Seuil',
      iconCodePoint: Icons.casino.codePoint,
      cardColorValue: Colors.blue.toARGB32(),
      isLowestScoreWins: true,
      playerDeadConditionType:
          eliminatesOver == null ? null : PlayerDeadConditionType.over,
      playerDeadThreshold: eliminatesOver,
      gameOverConditionType:
          overAt == null
              ? null
              : (lastStanding
                  ? GameOverConditionType.lastPlayerOver
                  : GameOverConditionType.firstPlayerOver),
      gameOverThreshold: overAt,
    ));
  }

  Widget wrap() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GameProvider>.value(value: games),
        ChangeNotifierProvider<GameTypeProvider>.value(value: gameTypes),
        ChangeNotifierProvider<BackendProvider>(
            create: (_) => BackendProvider(null)),
        ChangeNotifierProvider<GroupProvider>(
            create: (_) => GroupProvider(db: db, enableStream: false)),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', ''), Locale('fr', '')],
        locale: const Locale('en', ''),
        home: GameBoardScreen(
          analysisRepo: NoAnalysis(),
          sounds: GameSounds(sounds),
        ),
      ),
    );
  }

  /// Creates a game of [typeId] with [names] and [rounds] already scored (one
  /// score per player, in seat order), without opening the board.
  Future<void> aGame(List<String> names,
      {int? typeId, List<List<int>> rounds = const []}) async {
    final id = await games.createGame('Partie', typeId, true, names, null);
    await games.loadGame(id);
    for (final row in rounds) {
      await games.addRoundWithScores({
        for (var i = 0; i < row.length; i++)
          games.currentPlayers[i].id!: row[i],
      });
    }
  }

  /// Opens the board on the current game, on a 420 x 900 phone.
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap());
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  Player playerNamed(String name) =>
      games.currentPlayers.firstWhere((p) => p.name == name);

  Future<void> _tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  /// "Round N" on the keypad: each score typed in seat order, then validated;
  /// then past the 100 ms the board waits before an end screen.
  Future<void> enterRound(WidgetTester tester, List<int> scores) async {
    await tester.tap(find.byKey(const Key('board_add_round')));
    await tester.pumpAndSettle();
    for (final score in scores) {
      for (final d in '$score'.split('')) {
        await _tapKey(tester, 'keypad_digit_$d');
      }
      await _tapKey(tester, 'keypad_primary');
    }
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  /// A tapped cell of [name] in the round at [roundIndex], set to [score].
  Future<void> editScore(
      WidgetTester tester, String name, int roundIndex, int score) async {
    final player = playerNamed(name);
    final round = games.currentRounds[roundIndex];
    await tester.tap(find.byKey(Key('board_cell_${player.id}_${round.id}')));
    await tester.pumpAndSettle();
    for (final d in '$score'.split('')) {
      await _tapKey(tester, 'keypad_digit_$d');
    }
    await _tapKey(tester, 'keypad_primary');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }
}
