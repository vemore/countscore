// What the board says about the end of a game: the badge on a finished one,
// and the end screen the game type's rule opens.
//
// The end screen opens on every path that can cross the threshold, and
// asks once per crossing.
//
// It runs after a score edit, after a round is added or deleted, and on the
// board's first build, behind `_gameOverDismissed`: the screen is not raised
// again for a crossing the user already answered, and the flag re-arms as soon
// as the condition is false again, so crossing a second time asks again.
//
// "Continue playing" is also stored on the device (SharedPreferences, keyed by
// the game's uuid, see `GameOverDismissals`), so leaving the board and coming
// back does not ask again — and the first-build check can exist at all.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'package:countscore/screens/game_end_screen.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/services/game_over_dismissals.dart';

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
    SharedPreferences.setMockInitialValues({});
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

  /// A game of a type that is over as soon as a player reaches 100, with one
  /// round, Alice already at [aliceScore] and Bob at 20.
  Future<void> aGamePast(int aliceScore, {bool lowestWins = false}) async {
    final typeId = await gameTypes.createGameType(GameType(
      name: 'Seuil',
      iconCodePoint: Icons.casino.codePoint,
      cardColorValue: Colors.blue.toARGB32(),
      isLowestScoreWins: lowestWins,
      gameOverConditionType: GameOverConditionType.firstPlayerOver,
      gameOverThreshold: 100,
    ));
    final gameId = await games.createGame(
        'Partie', typeId, lowestWins, ['Alice', 'Bob'], null);
    await games.loadGame(gameId);
    await games.addRound();
    await games.updateScore(
      games.currentPlayers.first.id!,
      games.currentRounds.single.id!,
      aliceScore,
    );
    await games.updateScore(
      games.currentPlayers.last.id!,
      games.currentRounds.single.id!,
      20,
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

  /// Pumps past the 100 ms the board waits before raising the end screen.
  Future<void> settleTheEndScreen(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  /// "Round N", then "Next" / "Validate round" on the keypad with nothing
  /// typed: a round of zeros, written in one go.
  Future<void> addARound(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('board_add_round')));
    await tester.pumpAndSettle();
    while (find.byKey(const Key('keypad_sheet')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('keypad_primary')));
      await tester.pumpAndSettle();
    }
    await settleTheEndScreen(tester);
  }

  Future<void> continuePlaying(WidgetTester tester) async {
    await tester.tap(find.text(l10n.continuePlay));
    await tester.pumpAndSettle();
  }

  /// Opens the board and answers the end screen its first build raises.
  Future<void> openAndContinue(WidgetTester tester) async {
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);
    expect(find.byType(GameEndScreen), findsOneWidget);
    await continuePlaying(tester);
  }

  /// Leaves the board — its State is disposed — and opens it again.
  Future<void> leaveAndComeBack(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);
  }

  Future<bool> storedDismissal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(GameOverDismissals.key(games.currentGame!.uuid!)) ??
        false;
  }

  testWidgets('opening a board past its threshold asks once', (tester) async {
    await aGamePast(150);
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);
    expect(find.byType(GameEndScreen), findsOneWidget);

    await continuePlaying(tester);
    await addARound(tester);
    expect(find.byType(GameEndScreen), findsNothing);
  });

  group('the rule ends the game on its end screen', () {
    final headline = find.byKey(const Key('game_end_headline'));

    testWidgets('naming the highest total on a highest-wins type',
        (tester) async {
      await aGamePast(150);
      await tester.pumpWidget(wrap());
      await settleTheEndScreen(tester);

      expect(find.byType(GameEndScreen), findsOneWidget);
      expect(tester.widget<Text>(headline).data, l10n.gameEndWinner('Alice'));
      expect(games.currentGame!.isFinished, isTrue,
          reason: 'the end screen records the game as finished');
    });

    testWidgets('naming the lowest total on a lowest-wins type',
        (tester) async {
      await aGamePast(150, lowestWins: true);
      await tester.pumpWidget(wrap());
      await settleTheEndScreen(tester);

      expect(find.byType(GameEndScreen), findsOneWidget);
      expect(tester.widget<Text>(headline).data, l10n.gameEndWinner('Bob'));
    });

    testWidgets('"Continue playing" returns to the board, the game open',
        (tester) async {
      await aGamePast(150);
      await tester.pumpWidget(wrap());
      await settleTheEndScreen(tester);

      await continuePlaying(tester);
      expect(find.byType(GameEndScreen), findsNothing);
      expect(find.byKey(const Key('board_add_round')), findsOneWidget);
      expect(games.currentGame!.isFinished, isFalse);
      expect(find.byKey(const Key('board_finished_badge')), findsNothing);
    });

    testWidgets('its back button leaves the game finished', (tester) async {
      await aGamePast(150);
      await tester.pumpWidget(wrap());
      await settleTheEndScreen(tester);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(GameEndScreen), findsNothing);
      expect(games.currentGame!.isFinished, isTrue);
    });
  });

  testWidgets('a finished game reaches its end screen from the app bar',
      (tester) async {
    await aGamePast(10);
    await games.setGameFinished(games.currentGame!.id!, true);
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);
    expect(find.byType(GameEndScreen), findsNothing,
        reason: 'a finished game is not announced again');

    await tester.tap(find.byKey(const Key('board_game_end')));
    await tester.pumpAndSettle();
    expect(find.byType(GameEndScreen), findsOneWidget);
    expect(find.byKey(const Key('game_end_continue')), findsNothing,
        reason: 'only the rule ending the game offers to keep playing');
  });

  testWidgets('an open game has no end-screen entry in the app bar',
      (tester) async {
    await aGamePast(10);
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);
    expect(find.byKey(const Key('board_game_end')), findsNothing);
  });

  testWidgets('opening a finished game past its threshold raises nothing',
      (tester) async {
    await aGamePast(150);
    await games.setGameFinished(games.currentGame!.id!, true);
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);
    expect(find.byType(GameEndScreen), findsNothing);
  });

  testWidgets('a crossing on a score edit is noticed by the next round',
      (tester) async {
    await aGamePast(10);
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);
    expect(find.byType(GameEndScreen), findsNothing);

    // Crossed outside the board — another device, a sync.
    await games.updateScore(
      games.currentPlayers.first.id!,
      games.currentRounds.first.id!,
      150,
    );
    await addARound(tester);
    expect(find.byType(GameEndScreen), findsOneWidget);
  });

  testWidgets('"Continue playing" survives leaving the board', (tester) async {
    await aGamePast(150);
    await openAndContinue(tester);
    expect(await storedDismissal(), isTrue);

    await leaveAndComeBack(tester);
    expect(find.byType(GameEndScreen), findsNothing,
        reason: 'the first build must not ask a question already answered');

    await addARound(tester);
    expect(find.byType(GameEndScreen), findsNothing,
        reason: 'the answer is stored on the device, not in the board State');
  });

  testWidgets('a game brought back under its threshold asks again',
      (tester) async {
    await aGamePast(150);
    await openAndContinue(tester);

    // A correction puts Alice back under 100: the crossing is undone, so the
    // stored answer goes.
    await games.updateScore(
      games.currentPlayers.first.id!,
      games.currentRounds.first.id!,
      10,
    );
    await addARound(tester);
    expect(find.byType(GameEndScreen), findsNothing);
    expect(await storedDismissal(), isFalse);

    // And crossing it a second time is a new event, asked once — even after
    // the board was left in between.
    await games.updateScore(
      games.currentPlayers.first.id!,
      games.currentRounds.first.id!,
      150,
    );
    await leaveAndComeBack(tester);
    expect(find.byType(GameEndScreen), findsOneWidget);
    await continuePlaying(tester);
    await addARound(tester);
    expect(find.byType(GameEndScreen), findsNothing);
  });

  // `firstPlayerOver` means "reaches" since 2026-09-19: a total equal to the
  // threshold ends the game, as the box rules say.
  testWidgets('a total exactly on the threshold ends the game', (tester) async {
    await aGamePast(100);
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);
    expect(find.byType(GameEndScreen), findsOneWidget);
  });

  testWidgets('one point short of the threshold does not', (tester) async {
    await aGamePast(99);
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);
    expect(find.byType(GameEndScreen), findsNothing);
  });

  testWidgets('a game that never crosses its threshold is left alone',
      (tester) async {
    await aGamePast(10);
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);

    await addARound(tester);
    expect(find.byType(GameEndScreen), findsNothing);
  });

  // The game list has shown a finished game as finished since v12; the board
  // showed nothing, so the two disagreed about a fact one of them displayed.
  group('the finished badge', () {
    final badge = find.byKey(const Key('board_finished_badge'));

    testWidgets('is absent while the game is open', (tester) async {
      await aGamePast(10);
      await tester.pumpWidget(wrap());
      await settleTheEndScreen(tester);

      expect(badge, findsNothing);
    });

    testWidgets('appears as soon as the game is finished', (tester) async {
      await aGamePast(10);
      await tester.pumpWidget(wrap());
      await settleTheEndScreen(tester);

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
