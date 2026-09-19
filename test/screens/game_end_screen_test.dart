// The game-end screen: who won, the podium, the rest in rank order, "Play
// again" and — only with a server configured — "Analysis". Home's "End game"
// opens it too (the board's paths are in `game_board_end_of_game_test.dart`).
//
// The board "Play again" opens is injected (`boardBuilder`): the real
// `GameBoardScreen` reaches the `AppDatabase` singleton. Writes run on a real
// in-memory database, so they go through `runAsync`, as in
// `play_again_test.dart`.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/screens/game_end_screen.dart';
import 'package:countscore/screens/home_screen.dart';
import 'package:countscore/services/drift/database.dart';

const _boardKey = Key('test_board');

Widget _board(BuildContext context) =>
    const Scaffold(key: _boardKey, body: Text('board'));

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

  Widget wrap(Widget home, {String? server}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GameProvider>.value(value: games),
        ChangeNotifierProvider<GameTypeProvider>.value(value: gameTypes),
        ChangeNotifierProvider<BackendProvider>(
            create: (_) => BackendProvider(server)),
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
        home: home,
      ),
    );
  }

  /// A lowest-wins game of five, one round scored, loaded as current:
  /// Dora 10, Alice 30, Bob 20, Chloé 40, Eve 50 — Dora wins, Bob second,
  /// Alice third, then Chloé and Eve.
  Future<Game> aScoredGame({bool finished = true}) async {
    final id = await games.createGame('Skyjo 3', null, true,
        ['Alice', 'Bob', 'Chloé', 'Dora', 'Eve'], null);
    await games.loadGame(id);
    await games.addRound();
    final round = games.currentRounds.single.id!;
    final scores = {'Alice': 30, 'Bob': 20, 'Chloé': 40, 'Dora': 10, 'Eve': 50};
    for (final p in games.currentPlayers) {
      await games.updateScore(p.id!, round, scores[p.name]!);
    }
    if (finished) await games.setGameFinished(id, true);
    await games.loadGames();
    await games.loadGame(id);
    return games.currentGame!;
  }

  /// Pumps until [finder] shows, letting the real database's writes land.
  Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
    await tester.runAsync(() async {
      for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
  }

  /// Taps Share and waits for [done]: the standings' PNG is drawn by the
  /// engine, which fake time does not drive.
  Future<void> tapShare(WidgetTester tester, bool Function() done) async {
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('share_result')));
      for (var i = 0; i < 200 && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets('names the winner, the podium and the rest in rank order',
      (tester) async {
    await tester.runAsync(aScoredGame);
    await tester.pumpWidget(wrap(const GameEndScreen(boardBuilder: _board)));
    await tester.pumpAndSettle();

    expect(find.text(l10n.gameEndWinner('Dora')), findsOneWidget);
    expect(
      find.text('${l10n.gameEndRounds(1)} · ${l10n.gameEndLowestWins}'),
      findsOneWidget,
    );
    for (final (place, name, total) in [
      (0, 'Dora', '10'),
      (1, 'Bob', '20'),
      (2, 'Alice', '30'),
    ]) {
      final step = find.byKey(Key('ranking_podium_$place'));
      expect(find.descendant(of: step, matching: find.text(name)),
          findsOneWidget);
      expect(find.descendant(of: step, matching: find.text(total)),
          findsOneWidget);
    }
    // Places 4 and 5, below the podium, in that order.
    final chloe = tester.getTopLeft(find.text('Chloé'));
    final eve = tester.getTopLeft(find.text('Eve'));
    expect(chloe.dy, lessThan(eve.dy));
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.byKey(const Key('game_end_continue')), findsNothing);
  });

  testWidgets('the share action hands the standings to the share sheet',
      (tester) async {
    await tester.runAsync(aScoredGame);
    String? shared;
    String? sharedSubject;
    await tester.pumpWidget(wrap(GameEndScreen(
      boardBuilder: _board,
      share: (text, {subject, image}) async {
        shared = text;
        sharedSubject = subject;
      },
    )));
    await tester.pumpAndSettle();

    await tapShare(tester, () => shared != null);

    expect(sharedSubject, l10n.shareResultSubject('Skyjo 3'));
    expect(
      shared,
      contains('1. Dora — 10 points\n'
          '2. Bob — 20 points\n'
          '3. Alice — 30 points\n'
          '4. Chloé — 40 points\n'
          '5. Eve — 50 points'),
    );
    expect(shared, contains(l10n.gameEndLowestWins));
    expect(shared,
        contains('https://play.google.com/store/apps/details?id=com.vemore.countscore'));
  });

  testWidgets('a share sheet that fails to open is reported, not thrown',
      (tester) async {
    await tester.runAsync(aScoredGame);
    var called = false;
    await tester.pumpWidget(wrap(GameEndScreen(
      boardBuilder: _board,
      share: (text, {subject, image}) async {
        called = true;
        throw Exception('no share sheet');
      },
    )));
    await tester.pumpAndSettle();

    await tapShare(tester, () => called);

    expect(find.text(l10n.shareFailed), findsOneWidget);
  });

  testWidgets('"Play again" creates the next game with the same players',
      (tester) async {
    final source = await tester.runAsync(aScoredGame);
    await tester.pumpWidget(wrap(const GameEndScreen(boardBuilder: _board)));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('game_end_play_again')));
    });
    await pumpUntil(tester, find.byKey(_boardKey));

    expect(find.byKey(_boardKey), findsOneWidget);
    await tester.runAsync(() async {
      await games.loadGames();
      expect(games.games, hasLength(2));
      final copy = games.games.singleWhere((g) => g.id != source!.id);
      expect(games.currentGame?.id, copy.id, reason: 'the board is the new game');
      expect(copy.name, 'Skyjo 4');
      expect(copy.isFinished, isFalse);
      expect(copy.isLowestScoreWins, isTrue);
      final players = await games.getPlayersOfGame(copy.id!);
      expect(players.map((p) => p.name),
          ['Alice', 'Bob', 'Chloé', 'Dora', 'Eve']);
    });
  });

  group('"Analysis"', () {
    final analysis = find.byKey(const Key('game_end_analysis'));
    final playAgain = find.byKey(const Key('game_end_play_again'));

    testWidgets('is absent without a server, and Play again spans the row',
        (tester) async {
      await tester.runAsync(aScoredGame);
      await tester.pumpWidget(wrap(const GameEndScreen(boardBuilder: _board)));
      await tester.pumpAndSettle();

      expect(analysis, findsNothing);
      expect(tester.getSize(playAgain).width, 800 - 32);
    });

    testWidgets('is offered once a server is configured', (tester) async {
      await tester.runAsync(aScoredGame);
      await tester.pumpWidget(wrap(const GameEndScreen(boardBuilder: _board),
          server: 'https://scores.example'));
      await tester.pumpAndSettle();

      expect(analysis, findsOneWidget);
      expect(find.text(l10n.gameEndAnalysis), findsOneWidget);
      expect(tester.getSize(playAgain).width, lessThan(800 / 2));
    });
  });

  testWidgets('"End game" from the home list opens the end screen',
      (tester) async {
    final game = await tester.runAsync(() => aScoredGame(finished: false));
    await tester.pumpWidget(wrap(const HomeScreen(boardBuilder: _board)));
    await tester.pumpAndSettle();

    // Fired through `onSelected`, for the reason given in
    // `home_screen_finish_menu_test.dart`.
    final finder = find.byWidgetPredicate((w) => w is PopupMenuButton);
    final dynamic button = tester.widget(finder.first);
    await tester.runAsync(() async {
      button.onSelected('finish_game');
    });
    await pumpUntil(tester, find.byType(GameEndScreen));

    expect(find.byType(GameEndScreen), findsOneWidget);
    expect(find.text(l10n.gameEndWinner('Dora')), findsOneWidget);
    await tester.runAsync(() async {
      await games.loadGames();
      expect(games.games.single.id, game!.id);
      expect(games.games.single.isFinished, isTrue);
    });
  });
}
