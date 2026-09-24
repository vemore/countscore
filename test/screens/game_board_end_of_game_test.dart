// What the board says about the end of a game: the badge on a finished one,
// and the standings the game type's rule opens.
//
// The standings open on every path that can cross the threshold, and ask once
// per crossing.
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
import 'package:countscore/models/round.dart';
import 'package:countscore/models/score.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/repositories/game_analysis_repository.dart';
import 'package:countscore/screens/game_board_screen.dart';
import 'package:countscore/screens/standings_screen.dart';
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
    expect(find.byType(StandingsScreen), findsOneWidget);
    await continuePlaying(tester);
  }

  /// Leaves the board — its State is disposed — and opens it again.
  Future<void> leaveAndComeBack(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);
  }

  bool roundButtonEnabled(WidgetTester tester) =>
      tester
          .widget<FilledButton>(find.byKey(const Key('board_add_round')))
          .onPressed !=
      null;

  Future<bool> storedDismissal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(GameOverDismissals.key(games.currentGame!.uuid!)) ??
        false;
  }

  testWidgets('opening a board past its threshold asks once', (tester) async {
    await aGamePast(150);
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);
    expect(find.byType(StandingsScreen), findsOneWidget);

    await continuePlaying(tester);
    await addARound(tester);
    expect(find.byType(StandingsScreen), findsNothing);
  });

  group('the rule ends the game on its end screen', () {
    final headline = find.byKey(const Key('game_end_headline'));

    testWidgets('naming the highest total on a highest-wins type',
        (tester) async {
      await aGamePast(150);
      await tester.pumpWidget(wrap());
      await settleTheEndScreen(tester);

      expect(find.byType(StandingsScreen), findsOneWidget);
      expect(tester.widget<Text>(headline).data, l10n.gameEndWinner('Alice'));
      expect(games.currentGame!.isFinished, isTrue,
          reason: 'the end screen records the game as finished');
    });

    testWidgets('naming the lowest total on a lowest-wins type',
        (tester) async {
      await aGamePast(150, lowestWins: true);
      await tester.pumpWidget(wrap());
      await settleTheEndScreen(tester);

      expect(find.byType(StandingsScreen), findsOneWidget);
      expect(tester.widget<Text>(headline).data, l10n.gameEndWinner('Bob'));
    });

    testWidgets('"Continue playing" returns to the board, the game open',
        (tester) async {
      await aGamePast(150);
      await tester.pumpWidget(wrap());
      await settleTheEndScreen(tester);

      await continuePlaying(tester);
      expect(find.byType(StandingsScreen), findsNothing);
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
      expect(find.byType(StandingsScreen), findsNothing);
      expect(games.currentGame!.isFinished, isTrue);
    });
  });

  // One button for the standings, finished or not: the trophy that opened a
  // second, near-identical screen is gone
  // (wip/done/2026-09-20-ranking-and-end-screen-are-the-same-screen.md).
  testWidgets('a finished game has exactly one app-bar way to its standings',
      (tester) async {
    await aGamePast(10);
    await games.setGameFinished(games.currentGame!.id!, true);
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);
    expect(find.byType(StandingsScreen), findsNothing,
        reason: 'a finished game is not announced again');
    expect(find.byKey(const Key('board_standings')), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_outlined), findsNothing,
        reason: 'the second button is gone');
    expect(find.byTooltip(l10n.ranking), findsOneWidget);

    await tester.tap(find.byKey(const Key('board_standings')));
    await tester.pumpAndSettle();
    expect(find.byType(StandingsScreen), findsOneWidget);
    expect(find.byKey(const Key('game_end_headline')), findsOneWidget,
        reason: 'a finished game shows its result');
    expect(find.byKey(const Key('game_end_continue')), findsNothing,
        reason: 'only the rule ending the game offers to keep playing');
  });

  testWidgets('an open game reaches the same button, without a result',
      (tester) async {
    await aGamePast(10);
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);
    expect(find.byKey(const Key('board_standings')), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_outlined), findsNothing);

    await tester.tap(find.byKey(const Key('board_standings')));
    await tester.pumpAndSettle();
    expect(find.byType(StandingsScreen), findsOneWidget);
    expect(find.byKey(const Key('game_end_headline')), findsNothing,
        reason: 'the game is not over');
    expect(find.byKey(const Key('ranking_play_again')), findsOneWidget);
  });

  testWidgets('opening a finished game past its threshold raises nothing',
      (tester) async {
    await aGamePast(150);
    await games.setGameFinished(games.currentGame!.id!, true);
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);
    expect(find.byType(StandingsScreen), findsNothing);
  });

  // Until 2026-09-24 a crossing made outside the board waited for the next
  // round typed on it; the board now listens to the provider's totals.
  testWidgets('a crossing made outside the board is noticed at once',
      (tester) async {
    await aGamePast(10);
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);
    expect(find.byType(StandingsScreen), findsNothing);

    // Crossed outside the board — another device, a sync.
    await games.updateScore(
      games.currentPlayers.first.id!,
      games.currentRounds.first.id!,
      150,
    );
    await settleTheEndScreen(tester);
    expect(find.byType(StandingsScreen), findsOneWidget);
    expect(games.currentGame!.isFinished, isTrue);
  });

  testWidgets('"Continue playing" survives leaving the board', (tester) async {
    await aGamePast(150);
    await openAndContinue(tester);
    expect(await storedDismissal(), isTrue);

    await leaveAndComeBack(tester);
    expect(find.byType(StandingsScreen), findsNothing,
        reason: 'the first build must not ask a question already answered');

    await addARound(tester);
    expect(find.byType(StandingsScreen), findsNothing,
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
    expect(find.byType(StandingsScreen), findsNothing);
    expect(await storedDismissal(), isFalse);

    // And crossing it a second time is a new event, asked once — even when
    // it happens while the board is closed.
    await tester.pumpWidget(const SizedBox());
    await games.updateScore(
      games.currentPlayers.first.id!,
      games.currentRounds.first.id!,
      150,
    );
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);
    expect(find.byType(StandingsScreen), findsOneWidget);
    await continuePlaying(tester);
    await addARound(tester);
    expect(find.byType(StandingsScreen), findsNothing);
  });

  // `firstPlayerOver` means "reaches" since 2026-09-19: a total equal to the
  // threshold ends the game, as the box rules say.
  testWidgets('a total exactly on the threshold ends the game', (tester) async {
    await aGamePast(100);
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);
    expect(find.byType(StandingsScreen), findsOneWidget);
  });

  testWidgets('one point short of the threshold does not', (tester) async {
    await aGamePast(99);
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);
    expect(find.byType(StandingsScreen), findsNothing);
  });

  testWidgets('a game that never crosses its threshold is left alone',
      (tester) async {
    await aGamePast(10);
    await tester.pumpWidget(wrap());
    await settleTheEndScreen(tester);

    await addARound(tester);
    expect(find.byType(StandingsScreen), findsNothing);
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

      // A finished game takes no new round until it is reopened
      // (2026-09-24; before, the button stayed enabled).
      expect(roundButtonEnabled(tester), isFalse);

      await games.setGameFinished(games.currentGame!.id!, false);
      await tester.pumpAndSettle();
      expect(badge, findsNothing);
      expect(roundButtonEnabled(tester), isTrue);
    });
  });

  // A game whose type ends on the last player standing ends reliably
  // (wip/done/2026-09-23-a-game-with-one-player-left-does-not-reliably-end-itself.md).
  group('a ZapZap game with one player left', () {
    /// A seeded ZapZap (`lastPlayerOver`/100, out past 100) with one round:
    /// Alice 90, Bob 110 (out), Carol 50.
    Future<void> aZapZapGame() async {
      await gameTypes.loadGameTypes();
      final zapzap =
          gameTypes.gameTypes.singleWhere((t) => t.builtinKey == 'zapzap');
      expect(zapzap.gameOverConditionType, GameOverConditionType.lastPlayerOver);
      final gameId = await games.createGame(
          'ZapZap', zapzap.id, true, ['Alice', 'Bob', 'Carol'], null);
      await games.loadGame(gameId);
      final ids = [for (final p in games.currentPlayers) p.id!];
      await games.addRoundWithScores({ids[0]: 90, ids[1]: 110, ids[2]: 50});
    }

    Future<void> tapKey(WidgetTester tester, String key) async {
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    /// Round 2 on the keypad: Alice takes [aliceScore], Carol 0. Bob is out and
    /// is not asked.
    Future<void> typeRoundTwo(WidgetTester tester, int aliceScore) async {
      await tester.tap(find.byKey(const Key('board_add_round')));
      await tester.pumpAndSettle();
      for (final d in '$aliceScore'.split('')) {
        await tapKey(tester, 'keypad_digit_$d');
      }
      await tapKey(tester, 'keypad_primary'); // Alice -> Carol
      await tapKey(tester, 'keypad_primary'); // Validate round
      await settleTheEndScreen(tester);
    }

    /// "Reopen" in the board's menu. Selected through `onSelected`, as in
    /// undo_snack_bar_test.dart: the test font lays the open menu out wider
    /// than a device does.
    Future<void> reopenFromTheMenu(WidgetTester tester) async {
      final dynamic menu =
          tester.widget(find.byWidgetPredicate((w) => w is PopupMenuButton));
      await tester.runAsync(() async {
        await menu.onSelected('finish_game');
      });
      await tester.pumpAndSettle();
    }

    testWidgets(
        'the round that leaves one player standing finishes the game and '
        'opens the end screen; the round button stays disabled until Reopen',
        (tester) async {
      await aZapZapGame();
      await tester.pumpWidget(wrap());
      await settleTheEndScreen(tester);
      expect(find.byType(StandingsScreen), findsNothing);
      expect(roundButtonEnabled(tester), isTrue);

      await typeRoundTwo(tester, 15); // Alice 105: only Carol is left
      expect(games.currentGame!.isFinished, isTrue);
      expect(find.byType(StandingsScreen), findsOneWidget);
      expect(find.byKey(const Key('game_end_headline')), findsOneWidget);

      // Back to the board: the game stays finished and takes no round.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(StandingsScreen), findsNothing);
      expect(games.currentGame!.isFinished, isTrue);
      expect(roundButtonEnabled(tester), isFalse);

      // Leaving and coming back does not bring it back either.
      await leaveAndComeBack(tester);
      expect(find.byType(StandingsScreen), findsNothing);
      expect(roundButtonEnabled(tester), isFalse);

      await reopenFromTheMenu(tester);
      expect(games.currentGame!.isFinished, isFalse);
      expect(roundButtonEnabled(tester), isTrue);
    });

    testWidgets('"Continue playing" brings the round button back',
        (tester) async {
      await aZapZapGame();
      await tester.pumpWidget(wrap());
      await settleTheEndScreen(tester);

      await typeRoundTwo(tester, 15);
      expect(find.byType(StandingsScreen), findsOneWidget);
      expect(games.currentGame!.isFinished, isTrue);

      await continuePlaying(tester);
      expect(games.currentGame!.isFinished, isFalse);
      expect(roundButtonEnabled(tester), isTrue);
    });

    testWidgets('a round that leaves two players standing does not end it',
        (tester) async {
      await aZapZapGame();
      await tester.pumpWidget(wrap());
      await settleTheEndScreen(tester);

      await typeRoundTwo(tester, 10); // Alice 100: not past 100
      expect(find.byType(StandingsScreen), findsNothing);
      expect(games.currentGame!.isFinished, isFalse);
      expect(roundButtonEnabled(tester), isTrue);
    });

    testWidgets(
        'a round delivered through the provider, as sync does, ends the game '
        'on a board that did not type it', (tester) async {
      await aZapZapGame();
      await tester.pumpWidget(wrap());
      await settleTheEndScreen(tester);
      expect(find.byType(StandingsScreen), findsNothing);

      // Another device typed round 2; the pull wrote it to the database
      // underneath this board, then reloaded the provider.
      final game = games.currentGame!;
      final ids = [for (final p in games.currentPlayers) p.id!];
      final roundId = await DriftRoundRepository(db)
          .create(Round(gameId: game.id!, roundNumber: 2));
      final scores = DriftScoreRepository(db);
      await scores.upsert(Score(playerId: ids[0], roundId: roundId, value: 30));
      await scores.upsert(Score(playerId: ids[2], roundId: roundId, value: 0));
      await games.refreshFromSync();
      await settleTheEndScreen(tester);

      expect(games.currentRounds, hasLength(2));
      expect(find.byType(StandingsScreen), findsOneWidget);
      expect(games.currentGame!.isFinished, isTrue);
      final stored = await DriftGameRepository(db).getById(game.id!);
      expect(stored!.isFinished, isTrue,
          reason: 'the end is stored, so it syncs as ended_at');
    });

    testWidgets('a pull that changes no total does not ask', (tester) async {
      await aZapZapGame();
      await tester.pumpWidget(wrap());
      await settleTheEndScreen(tester);

      await games.refreshFromSync();
      await settleTheEndScreen(tester);
      expect(find.byType(StandingsScreen), findsNothing);
      expect(games.currentGame!.isFinished, isFalse);
    });
  });

  // Regression: the types that end on the first player to reach a total keep
  // ending as they did.
  group('a firstPlayerOver type', () {
    Future<void> aSeededGame(String key) async {
      await gameTypes.loadGameTypes();
      final type = gameTypes.gameTypes.singleWhere((t) => t.builtinKey == key);
      expect(type.gameOverConditionType, GameOverConditionType.firstPlayerOver);
      final gameId = await games.createGame(
          key, type.id, type.isLowestScoreWins, ['Alice', 'Bob'], null);
      await games.loadGame(gameId);
    }

    Future<void> typeRound(WidgetTester tester, int aliceScore) async {
      await tester.tap(find.byKey(const Key('board_add_round')));
      await tester.pumpAndSettle();
      for (final d in '$aliceScore'.split('')) {
        await tester.tap(find.byKey(Key('keypad_digit_$d')));
        await tester.pumpAndSettle();
      }
      while (find.byKey(const Key('keypad_sheet')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('keypad_primary')));
        await tester.pumpAndSettle();
      }
      await settleTheEndScreen(tester);
    }

    for (final (key, threshold) in [('president', 10), ('uno', 500)]) {
      testWidgets('$key ends when a player reaches $threshold, not before',
          (tester) async {
        await aSeededGame(key);
        await tester.pumpWidget(wrap());
        await settleTheEndScreen(tester);

        await typeRound(tester, threshold - 1);
        expect(find.byType(StandingsScreen), findsNothing);
        expect(games.currentGame!.isFinished, isFalse);

        await typeRound(tester, 1);
        expect(find.byType(StandingsScreen), findsOneWidget);
        expect(games.currentGame!.isFinished, isTrue);
        expect(
            tester
                .widget<Text>(find.byKey(const Key('game_end_headline')))
                .data,
            l10n.gameEndWinner('Alice'));

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(roundButtonEnabled(tester), isFalse);
      });
    }
  });
}
