// What the board says about the end of a game: the badge on a finished one,
// and the game-over dialog.
//
// The game-over dialog fires on every path that can cross the threshold, and
// asks once per crossing.
//
// It used to have a single call site — the score dialog — so a game could sit
// past its condition with no dialog as long as the crossing score was not the
// last cell touched. It now also runs after a round is added and after one is
// deleted, behind `_gameOverDismissed`: the dialog is not raised again for a
// crossing the user already answered, and the flag re-arms as soon as the
// condition is false again, so crossing a second time asks again.
//
// The flag is in-memory only, by decision: nothing records "Continue playing",
// so a check on the board's first build would reopen the dialog every time the
// board is opened for a game past its threshold.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game_analysis.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/repositories/game_analysis_repository.dart';
import 'package:countscore/screens/game_board_screen.dart';
import 'package:countscore/services/drift/database.dart';

/// The board asks on open whether this game has a stored analysis; nothing in
/// these tests is about that, and the default reaches the real database.
class _NoAnalysis implements GameAnalysisRepository {
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

void main() {
  late AppDatabase db;
  late GameProvider games;
  late GameTypeProvider gameTypes;
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
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
  });

  tearDown(() => db.close());

  /// A game of a type that is over as soon as a player passes 100, with one
  /// round and Alice already at [aliceScore].
  Future<void> aGamePast(int aliceScore) async {
    final typeId = await gameTypes.createGameType(GameType(
      name: 'Seuil',
      iconCodePoint: Icons.casino.codePoint,
      cardColorValue: Colors.blue.toARGB32(),
      isLowestScoreWins: false,
      gameOverConditionType: GameOverConditionType.firstPlayerOver,
      gameOverThreshold: 100,
    ));
    final gameId =
        await games.createGame('Partie', typeId, false, ['Alice', 'Bob'], null);
    await games.loadGame(gameId);
    await games.addRound();
    await games.updateScore(
      games.currentPlayers.first.id!,
      games.currentRounds.single.id!,
      aliceScore,
    );
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
        home: GameBoardScreen(analysisRepo: _NoAnalysis()),
      ),
    );
  }

  /// Pumps past the 100 ms the board waits before raising the dialog.
  Future<void> settleTheDialog(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  Future<void> addARound(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('board_add_round')));
    await settleTheDialog(tester);
  }

  testWidgets('opening a board past its threshold raises nothing',
      (tester) async {
    await aGamePast(150);
    await tester.pumpWidget(wrap());
    await settleTheDialog(tester);

    expect(find.text(l10n.gameOverTitle), findsNothing,
        reason: 'nothing records "Continue playing", so a check on first build '
            'would reopen the dialog on every single opening');
  });

  testWidgets('adding a round notices a threshold already crossed',
      (tester) async {
    await aGamePast(150);
    await tester.pumpWidget(wrap());
    await settleTheDialog(tester);

    await addARound(tester);
    expect(find.text(l10n.gameOverTitle), findsOneWidget);
  });

  testWidgets('"Continue playing" is not asked again for the same crossing',
      (tester) async {
    await aGamePast(150);
    await tester.pumpWidget(wrap());
    await settleTheDialog(tester);

    await addARound(tester);
    await tester.tap(find.text(l10n.continuePlay));
    await tester.pumpAndSettle();
    expect(find.text(l10n.gameOverTitle), findsNothing);

    await addARound(tester);
    expect(find.text(l10n.gameOverTitle), findsNothing,
        reason: 'the answer holds while the game stays over its threshold');
  });

  testWidgets('a game brought back under its threshold asks again',
      (tester) async {
    await aGamePast(150);
    await tester.pumpWidget(wrap());
    await settleTheDialog(tester);

    await addARound(tester);
    await tester.tap(find.text(l10n.continuePlay));
    await tester.pumpAndSettle();

    // A correction puts Alice back under 100: the crossing is undone, so the
    // flag re-arms.
    await games.updateScore(
      games.currentPlayers.first.id!,
      games.currentRounds.first.id!,
      10,
    );
    await addARound(tester);
    expect(find.text(l10n.gameOverTitle), findsNothing);

    // And crossing it a second time is a new event.
    await games.updateScore(
      games.currentPlayers.first.id!,
      games.currentRounds.first.id!,
      150,
    );
    await addARound(tester);
    expect(find.text(l10n.gameOverTitle), findsOneWidget);
  });

  testWidgets('a game that never crosses its threshold is left alone',
      (tester) async {
    await aGamePast(10);
    await tester.pumpWidget(wrap());
    await settleTheDialog(tester);

    await addARound(tester);
    expect(find.text(l10n.gameOverTitle), findsNothing);
  });

  // The game list has shown a finished game as finished since v12; the board
  // showed nothing, so the two disagreed about a fact one of them displayed.
  group('the finished badge', () {
    final badge = find.byKey(const Key('board_finished_badge'));

    testWidgets('is absent while the game is open', (tester) async {
      await aGamePast(10);
      await tester.pumpWidget(wrap());
      await settleTheDialog(tester);

      expect(badge, findsNothing);
    });

    testWidgets('appears as soon as the game is finished', (tester) async {
      await aGamePast(10);
      await tester.pumpWidget(wrap());
      await settleTheDialog(tester);

      await games.setGameFinished(games.currentGame!.id!, true);
      await tester.pumpAndSettle();
      expect(badge, findsOneWidget);
      expect(find.text(l10n.gameFinished), findsOneWidget);

      // Nothing is locked: a finished game still takes rounds.
      expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('board_add_round')))
              .onPressed,
          isNotNull);

      await games.setGameFinished(games.currentGame!.id!, false);
      await tester.pumpAndSettle();
      expect(badge, findsNothing);
    });
  });
}
