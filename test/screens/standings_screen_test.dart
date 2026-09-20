// The standings screen — the app's only one since 2026-09-20, in its two
// states (`wip/done/2026-09-20-ranking-and-end-screen-are-the-same-screen.md`,
// which merged `RankingScreen` and `GameEndScreen`):
//
// - an **open** game shows where it stands: the win rule on one line, the
//   podium, every player in the list under it, "Play again";
// - a **finished** one adds the winner's headline and, with a server
//   configured, "Analysis".
//
// Common to both: the players' board colours, the leader crowned, totals near
// the elimination threshold in orange, eliminated players struck out, and the
// share action that sends the standings as text and as a picture. The list
// under the podium holds every player, first to last
// (`wip/done/2026-09-20-podium-hides-the-first-three-from-the-list.md`).
//
// "Play again" is also covered in `play_again_test.dart`; the board's paths to
// this screen are in `game_board_end_of_game_test.dart`.
//
// Writes run on a real in-memory database, so they go through `runAsync`.

import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/screens/home_screen.dart';
import 'package:countscore/screens/standings_screen.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/utils/player_colors.dart';
import 'package:countscore/widgets/board_lanes.dart';
import 'package:countscore/widgets/player_avatars.dart';
import 'package:countscore/widgets/result_share_card.dart';
import 'package:countscore/widgets/share_result_button.dart';

const _boardKey = Key('test_board');

Widget _board(BuildContext context) =>
    const Scaffold(key: _boardKey, body: Text('board'));

final _headline = find.byKey(const Key('game_end_headline'));
final _analysis = find.byKey(const Key('game_end_analysis'));

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

  /// A game of five of a type that puts a player out over 100, one round
  /// scored — none with [playRound] false — loaded as current, open unless
  /// [finished]. Chloé is seated with her own colour.
  Future<void> aGameOfFive({
    required bool lowestWins,
    bool playRound = true,
    bool finished = false,
    Map<String, int> scores = const {
      'Alice': 30,
      'Bob': 20,
      'Chloé': 40,
      'Dora': 10,
      'Eve': 50,
    },
  }) async {
    final typeId = await gameTypes.createGameType(GameType(
      name: 'Soirée',
      iconCodePoint: Icons.casino.codePoint,
      cardColorValue: Colors.blue.toARGB32(),
      isLowestScoreWins: lowestWins,
      playerDeadConditionType: PlayerDeadConditionType.over,
      playerDeadThreshold: 100,
    ));
    final id = await games.createGame(
      'Soirée 1',
      typeId,
      lowestWins,
      ['Alice', 'Bob', 'Chloé', 'Dora', 'Eve'],
      {'Chloé': 0xFF00FF00},
    );
    await games.loadGame(id);
    if (playRound) {
      await games.addRound();
      final round = games.currentRounds.single.id!;
      for (final p in games.currentPlayers) {
        await games.updateScore(p.id!, round, scores[p.name]!);
      }
    }
    if (finished) await games.setGameFinished(id, true);
    await games.loadGame(id);
  }

  /// A lowest-wins game of five with no game type, one round scored, loaded as
  /// current: Dora 10, Bob 20, Alice 30, Chloé 40, Eve 50 — Dora wins.
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

  /// The reproduced ZapZap game of four (out above 100, the game over when the
  /// last player stands), five rounds: Alice out in round 1 with 101, Bob out
  /// in round 4 with 140, Chloé out in round 5 with 115, David alone at the
  /// end with 50. By total it is David, Alice, Chloé, Bob; by elimination
  /// order it is David, Chloé, Bob, Alice
  /// (`wip/done/2026-09-20-ranking-ignores-the-game-types-ranking-rule.md`).
  ///
  /// [rounds] stops the game short — four of them leave Chloé and David in,
  /// so an open game is not over.
  Future<GameType> anEliminationGame({
    required bool finished,
    int rounds = 5,
  }) async {
    // No `builtinKey`: the database already seeds a zapzap row, and the key is
    // unique among the live ones.
    final typeId = await gameTypes.createGameType(GameType(
      name: 'ZapZap',
      iconCodePoint: Icons.bolt.codePoint,
      cardColorValue: Colors.amber.toARGB32(),
      isLowestScoreWins: true,
      playerDeadConditionType: PlayerDeadConditionType.over,
      playerDeadThreshold: 100,
      gameOverConditionType: GameOverConditionType.lastPlayerOver,
      gameOverThreshold: 100,
    ));
    final id = await games.createGame(
        'ZapZap 1', typeId, true, ['Alice', 'Bob', 'Chloé', 'David'], null);
    await games.loadGame(id);
    for (final scores in const [
      {'Alice': 101, 'Bob': 20, 'Chloé': 10, 'David': 5},
      {'Bob': 30, 'Chloé': 20, 'David': 10},
      {'Bob': 40, 'Chloé': 30, 'David': 10},
      {'Bob': 50, 'Chloé': 25, 'David': 15},
      {'Chloé': 30, 'David': 10},
    ].take(rounds)) {
      await games.addRound();
      final round = games.currentRounds.last.id!;
      for (final p in games.currentPlayers) {
        final score = scores[p.name];
        if (score != null) await games.updateScore(p.id!, round, score);
      }
    }
    if (finished) await games.setGameFinished(id, true);
    await games.loadGames();
    await games.loadGame(id);
    return gameTypes.getGameTypeById(typeId)!;
  }

  /// [count] players, each 10 points apart so that nobody ties, highest wins.
  Future<void> aGameOf(int count) async {
    final names = [
      for (var i = 0; i < count; i++) 'P${i + 1}',
    ];
    final id = await games.createGame('Partie', null, false, names, null);
    await games.loadGame(id);
    await games.addRound();
    final round = games.currentRounds.single.id!;
    for (final (i, p) in games.currentPlayers.indexed) {
      await games.updateScore(p.id!, round, (count - i) * 10);
    }
    await games.loadGame(id);
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

  String nameIn(WidgetTester tester, Finder scope) => tester
      .widgetList<PlayerAvatar>(
          find.descendant(of: scope, matching: find.byType(PlayerAvatar)))
      .first
      .name;

  /// The names on the podium, first place first — one to three of them.
  List<String> podiumNames(WidgetTester tester) => [
        for (var place = 0; place < 3; place++)
          if (find.byKey(Key('ranking_podium_$place')).evaluate().isNotEmpty)
            nameIn(tester, find.byKey(Key('ranking_podium_$place'))),
      ];

  /// The rows under the podium, top to bottom.
  List<Finder> rowsInOrder(WidgetTester tester) {
    final rows = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('ranking_row_'));
    return [
      for (final element in rows.evaluate().toList()
        ..sort((a, b) => tester
            .getTopLeft(find.byWidget(a.widget))
            .dy
            .compareTo(tester.getTopLeft(find.byWidget(b.widget)).dy)))
        find.byWidget(element.widget),
    ];
  }

  /// The names of the list under the podium, top to bottom.
  List<String> rowNames(WidgetTester tester) =>
      [for (final row in rowsInOrder(tester)) nameIn(tester, row)];

  /// The place drawn on each row, top to bottom: the first `Text` of the row.
  List<String> rowPlaces(WidgetTester tester) => [
        for (final row in rowsInOrder(tester))
          tester
              .widgetList<Text>(
                  find.descendant(of: row, matching: find.byType(Text)))
              .first
              .data!,
      ];

  /// How far the standings can be scrolled: 0 when everything fits.
  double maxScrollExtent(WidgetTester tester) => tester
      .state<ScrollableState>(find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first)
      .position
      .maxScrollExtent;

  group('an open game', () {
    testWidgets('board colours, the leader crowned, no result yet',
        (tester) async {
      await tester.runAsync(() => aGameOfFive(lowestWins: true));
      await tester
          .pumpWidget(wrap(const StandingsScreen(boardBuilder: _board)));
      await tester.pumpAndSettle();

      // Every player in the colour the board gives them, and with the board's
      // two letters, podium and rows alike.
      final colours = playerColorsById(games.currentPlayers);
      for (final player in games.currentPlayers) {
        final avatars = tester.widgetList<PlayerAvatar>(find.byWidgetPredicate(
            (w) => w is PlayerAvatar && w.name == player.name));
        expect(avatars, isNotEmpty, reason: player.name);
        expect(avatars.every((a) => a.color == colours[player.id]), isTrue,
            reason: player.name);
        expect(find.text(player.name.substring(0, 2)), findsWidgets,
            reason: player.name);
      }
      expect(
        tester
            .widgetList<PlayerAvatar>(find.byWidgetPredicate(
                (w) => w is PlayerAvatar && w.name == 'Chloé'))
            .first
            .color,
        const Color(0xFF00FF00),
      );

      // One crown, on the leader: Dora, lowest total. The rows never crown.
      expect(find.byType(BoardCrown), findsOneWidget);
      final first = find.byKey(const Key('ranking_podium_0'));
      expect(find.descendant(of: first, matching: find.byType(BoardCrown)),
          findsOneWidget);
      expect(find.descendant(of: first, matching: find.text('Dora')),
          findsOneWidget);

      // The win rule is one line under the title.
      expect(find.text(l10n.ranking), findsOneWidget);
      expect(find.byKey(const Key('ranking_summary')), findsOneWidget);
      expect(find.textContaining(l10n.gameEndLowestWins), findsOneWidget);
      expect(find.byKey(const Key('ranking_play_again')), findsOneWidget);

      // Nothing of the finished state: the game is not over.
      expect(_headline, findsNothing);
      expect(find.byKey(const Key('game_end_continue')), findsNothing);
    });

    testWidgets('has no "Analysis" even with a server configured',
        (tester) async {
      await tester.runAsync(() => aGameOfFive(lowestWins: true));
      await tester.pumpWidget(wrap(const StandingsScreen(boardBuilder: _board),
          server: 'https://scores.example'));
      await tester.pumpAndSettle();

      expect(_headline, findsNothing);
      expect(_analysis, findsNothing);
      expect(find.byKey(const Key('ranking_play_again')), findsOneWidget);
    });
  });

  group('the list under the podium', () {
    for (final count in [2, 3, 4, 8]) {
      testWidgets('holds every player, first to last ($count players)',
          (tester) async {
        await tester.runAsync(() => aGameOf(count));
        await tester
            .pumpWidget(wrap(const StandingsScreen(boardBuilder: _board)));
        await tester.pumpAndSettle();

        final expected = [for (var i = 1; i <= count; i++) 'P$i'];
        expect(rowNames(tester), expected);
        expect(rowPlaces(tester),
            [for (var i = 1; i <= count; i++) '$i']);
        // The top three are the picture above the same rows.
        expect(podiumNames(tester), expected.take(3));
      });
    }

    testWidgets('does not scroll at 412×860 for four players', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.runAsync(() => aGameOf(4));
      await tester
          .pumpWidget(wrap(const StandingsScreen(boardBuilder: _board)));
      await tester.pumpAndSettle();
      expect(maxScrollExtent(tester), 0, reason: 'open');

      await tester.runAsync(() async {
        await games.setGameFinished(games.currentGame!.id!, true);
        await games.loadGame(games.currentGame!.id!);
      });
      await tester.pumpAndSettle();
      expect(_headline, findsOneWidget);
      expect(maxScrollExtent(tester), 0, reason: 'finished');
    });
  });

  testWidgets('a highest-wins game is shared in the order the screen draws',
      (tester) async {
    await tester.runAsync(() => aGameOfFive(lowestWins: false));
    String? shared;
    Uint8List? sharedImage;
    await tester.pumpWidget(wrap(StandingsScreen(
      boardBuilder: _board,
      share: (text, {subject, image}) async {
        shared = text;
        sharedImage = image;
      },
    )));
    await tester.pumpAndSettle();

    await tapShare(tester, () => shared != null);

    expect(rowNames(tester), ['Eve', 'Chloé', 'Alice', 'Bob', 'Dora']);
    // A PNG, the card's 400 logical pixels drawn at 3x.
    expect(sharedImage, isNotNull);
    expect(sharedImage!.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    final width = ByteData.sublistView(sharedImage!, 16, 20).getUint32(0);
    expect(width, ResultShareCard.width * 3);
    expect(
      shared,
      contains('1. Eve — 50 points\n'
          '2. Chloé — 40 points\n'
          '3. Alice — 30 points\n'
          '4. Bob — 20 points\n'
          '5. Dora — 10 points'),
    );
    expect(shared, contains('Soirée · ${l10n.gameEndRounds(1)}'));
  });

  testWidgets('the shared image ranks the players as the screen does',
      (tester) async {
    // Bob and Chloé tie for second: the seat breaks it, on both.
    await tester.runAsync(() => aGameOfFive(lowestWins: false, scores: {
          'Alice': 30,
          'Bob': 40,
          'Chloé': 40,
          'Dora': 10,
          'Eve': 50,
        }));
    await tester.pumpWidget(wrap(const StandingsScreen(boardBuilder: _board)));
    await tester.pumpAndSettle();
    final onScreen = rowNames(tester);
    expect(onScreen, ['Eve', 'Bob', 'Chloé', 'Alice', 'Dora']);

    // The card the share action draws into the PNG, caught before drawing.
    Widget? card;
    await tester.pumpWidget(wrap(Scaffold(
      appBar: AppBar(actions: [
        ShareResultButton(
          share: (text, {subject, image}) async {},
          renderImage: (context, widget) async {
            card = widget;
            return Uint8List(0);
          },
        ),
      ]),
    )));
    await tester.tap(find.byKey(const Key('share_result')));
    await tester.pumpAndSettle();
    expect(card, isA<ResultShareCard>());

    await tester.pumpWidget(wrap(Scaffold(
      body: SingleChildScrollView(child: Center(child: card)),
    )));
    await tester.pumpAndSettle();
    expect(rowNames(tester), onScreen);
    expect(find.byType(BoardCrown), findsOneWidget);
    expect(find.text(l10n.appTitle), findsOneWidget);
    expect(find.textContaining('Soirée · ${l10n.gameEndRounds(1)}'),
        findsOneWidget);
  });

  testWidgets('near the threshold in orange, eliminated players struck out',
      (tester) async {
    await tester.runAsync(() => aGameOfFive(lowestWins: true, scores: {
          'Alice': 30,
          'Bob': 20,
          'Chloé': 85,
          'Dora': 10,
          'Eve': 120,
        }));
    await tester.pumpWidget(wrap(const StandingsScreen(boardBuilder: _board)));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(StandingsScreen));
    // Chloé and Eve are past the podium, so each total is drawn once.
    final chloeTotal = tester.widget<Text>(find.text('85'));
    expect(chloeTotal.style?.color, boardWarningColor(context));
    // Bob is second: on the podium and in the list, neither of them orange.
    for (final bobTotal in tester.widgetList<Text>(find.text('20'))) {
      expect(bobTotal.style?.color, isNot(boardWarningColor(context)));
    }

    final eve = tester.widget<Text>(find.text('Eve'));
    expect(eve.style?.decoration, TextDecoration.lineThrough);
    expect(find.ancestor(of: find.text('Eve'), matching: find.byType(Opacity)),
        findsOneWidget);
    // Alice is third: her name is on the podium and in the list, struck out
    // on neither.
    for (final alice in tester.widgetList<Text>(find.text('Alice'))) {
      expect(alice.style?.decoration, isNot(TextDecoration.lineThrough));
    }
  });

  for (final (lowestWins, expected) in [
    (true, ['Dora', 'Bob', 'Alice', 'Chloé', 'Eve']),
    (false, ['Eve', 'Chloé', 'Alice', 'Bob', 'Dora']),
  ]) {
    testWidgets(
        '${lowestWins ? 'lowest' : 'highest'} wins: finishing the game does '
        'not change the order', (tester) async {
      await tester.runAsync(() => aGameOfFive(lowestWins: lowestWins));
      await tester
          .pumpWidget(wrap(const StandingsScreen(boardBuilder: _board)));
      await tester.pumpAndSettle();
      expect(rowNames(tester), expected);
      expect(podiumNames(tester), expected.take(3));

      await tester.runAsync(() async {
        await games.setGameFinished(games.currentGame!.id!, true);
        await games.loadGame(games.currentGame!.id!);
      });
      await tester.pumpAndSettle();
      expect(rowNames(tester), expected);
      expect(podiumNames(tester), expected.take(3));
      expect(tester.widget<Text>(_headline).data,
          l10n.gameEndWinner(expected.first));
    });
  }

  group('no crown without a sole leader', () {
    Future<void> expectNoCrownInEitherState(WidgetTester tester) async {
      await tester
          .pumpWidget(wrap(const StandingsScreen(boardBuilder: _board)));
      await tester.pumpAndSettle();
      expect(find.byType(BoardCrown), findsNothing, reason: 'open');

      await tester.runAsync(() async {
        await games.setGameFinished(games.currentGame!.id!, true);
        await games.loadGame(games.currentGame!.id!);
      });
      await tester.pumpAndSettle();
      expect(find.byType(BoardCrown), findsNothing, reason: 'finished');
    }

    testWidgets('a game with no round played', (tester) async {
      await tester
          .runAsync(() => aGameOfFive(lowestWins: true, playRound: false));
      await expectNoCrownInEitherState(tester);
      // Nobody won, so the finished game says only that it is over.
      expect(tester.widget<Text>(_headline).data, l10n.gameFinished);
    });

    testWidgets('one round of all zeros', (tester) async {
      await tester.runAsync(() => aGameOfFive(lowestWins: true, scores: {
            'Alice': 0,
            'Bob': 0,
            'Chloé': 0,
            'Dora': 0,
            'Eve': 0,
          }));
      await expectNoCrownInEitherState(tester);
    });
  });

  testWidgets('a tie shares a place: no crown, the same step, the same number',
      (tester) async {
    // Alice and Dora tie for the lead, Bob and Chloé for fourth.
    await tester.runAsync(() => aGameOfFive(lowestWins: true, scores: {
          'Alice': 10,
          'Bob': 40,
          'Chloé': 40,
          'Dora': 10,
          'Eve': 30,
        }));

    for (final finished in [false, true]) {
      if (finished) {
        await tester.runAsync(() async {
          await games.setGameFinished(games.currentGame!.id!, true);
          await games.loadGame(games.currentGame!.id!);
        });
      }
      await tester
          .pumpWidget(wrap(const StandingsScreen(boardBuilder: _board)));
      await tester.pumpAndSettle();
      final reason = finished ? 'finished' : 'open';

      expect(find.byType(BoardCrown), findsNothing, reason: reason);
      // Seat order within the tie, then Eve alone on the third step.
      expect(rowNames(tester), ['Alice', 'Dora', 'Eve', 'Bob', 'Chloé'],
          reason: reason);
      // The list shares the places the podium shares: 1, 1, 3, then 4, 4.
      expect(rowPlaces(tester), ['1', '1', '3', '4', '4'], reason: reason);

      int idOf(String name) =>
          games.currentPlayers.firstWhere((p) => p.name == name).id!;
      double stepOf(String name) =>
          tester.getSize(find.byKey(Key('ranking_step_${idOf(name)}'))).height;
      expect(stepOf('Alice'), stepOf('Dora'), reason: reason);
      expect(stepOf('Eve'), lessThan(stepOf('Alice')), reason: reason);

      for (final name in ['Bob', 'Chloé']) {
        expect(
            find.descendant(
                of: find.byKey(Key('ranking_row_${idOf(name)}')),
                matching: find.text('4')),
            findsOneWidget,
            reason: '$reason $name');
      }
    }
  });

  group('a finished game', () {
    testWidgets('names the winner, the podium and every place under it',
        (tester) async {
      await tester.runAsync(aScoredGame);
      await tester
          .pumpWidget(wrap(const StandingsScreen(boardBuilder: _board)));
      await tester.pumpAndSettle();

      expect(find.text(l10n.gameEndResults), findsOneWidget);
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
      // And the same five, in order, in the list under it.
      expect(rowNames(tester), ['Dora', 'Bob', 'Alice', 'Chloé', 'Eve']);
      expect(rowPlaces(tester), ['1', '2', '3', '4', '5']);
      expect(find.byKey(const Key('game_end_continue')), findsNothing);
    });

    testWidgets('the share action hands the standings to the share sheet',
        (tester) async {
      await tester.runAsync(aScoredGame);
      String? shared;
      String? sharedSubject;
      await tester.pumpWidget(wrap(StandingsScreen(
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
      expect(
          shared,
          contains(
              'https://play.google.com/store/apps/details?id=com.vemore.countscore'));
    });

    testWidgets('a share sheet that fails to open is reported, not thrown',
        (tester) async {
      await tester.runAsync(aScoredGame);
      var called = false;
      await tester.pumpWidget(wrap(StandingsScreen(
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
      await tester
          .pumpWidget(wrap(const StandingsScreen(boardBuilder: _board)));
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
        expect(games.currentGame?.id, copy.id,
            reason: 'the board is the new game');
        expect(copy.name, 'Skyjo 4');
        expect(copy.isFinished, isFalse);
        expect(copy.isLowestScoreWins, isTrue);
        final players = await games.getPlayersOfGame(copy.id!);
        expect(players.map((p) => p.name),
            ['Alice', 'Bob', 'Chloé', 'Dora', 'Eve']);
      });
    });

    group('"Analysis"', () {
      final playAgain = find.byKey(const Key('game_end_play_again'));

      testWidgets('is absent without a server, and Play again spans the row',
          (tester) async {
        await tester.runAsync(aScoredGame);
        await tester
            .pumpWidget(wrap(const StandingsScreen(boardBuilder: _board)));
        await tester.pumpAndSettle();

        expect(_analysis, findsNothing);
        expect(tester.getSize(playAgain).width, 800 - 32);
      });

      testWidgets('is offered once a server is configured', (tester) async {
        await tester.runAsync(aScoredGame);
        await tester.pumpWidget(wrap(
            const StandingsScreen(boardBuilder: _board),
            server: 'https://scores.example'));
        await tester.pumpAndSettle();

        expect(_analysis, findsOneWidget);
        expect(find.text(l10n.gameEndAnalysis), findsOneWidget);
        expect(tester.getSize(playAgain).width, lessThan(800 / 2));
      });
    });

    testWidgets('"End game" from the home list opens the standings',
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
      await pumpUntil(tester, find.byType(StandingsScreen));

      expect(find.byType(StandingsScreen), findsOneWidget);
      expect(find.text(l10n.gameEndWinner('Dora')), findsOneWidget);
      await tester.runAsync(() async {
        await games.loadGames();
        expect(games.games.single.id, game!.id);
        expect(games.games.single.isFinished, isTrue);
      });
    });
  });

  // The elimination rule, on the screen this entry is about
  // (`wip/done/2026-09-20-ranking-ignores-the-game-types-ranking-rule.md`):
  // finished, a game of a type that puts a player out and ends on the last
  // player standing ranks by who went out when, not by the total.
  group('a finished elimination game', () {
    testWidgets('ranks by the elimination order, not the total',
        (tester) async {
      await tester.runAsync(() => anEliminationGame(finished: true));
      await tester
          .pumpWidget(wrap(const StandingsScreen(boardBuilder: _board)));
      await tester.pumpAndSettle();

      // David alone at the end, then the others last-out first. Alice, out
      // after one hand with the second-lowest total, is last.
      expect(rowNames(tester), ['David', 'Chloé', 'Bob', 'Alice']);
      expect(rowPlaces(tester), ['1', '2', '3', '4']);
      expect(podiumNames(tester), ['David', 'Chloé', 'Bob']);
      expect(find.text(l10n.gameEndWinner('David')), findsOneWidget);
    });

    testWidgets('the share text and the home list agree with the screen',
        (tester) async {
      final type =
          await tester.runAsync(() => anEliminationGame(finished: true));
      String? shared;
      await tester.pumpWidget(wrap(StandingsScreen(
        boardBuilder: _board,
        share: (text, {subject, image}) async => shared = text,
      )));
      await tester.pumpAndSettle();
      await tapShare(tester, () => shared != null);

      expect(rowNames(tester), ['David', 'Chloé', 'Bob', 'Alice']);
      expect(
        shared,
        contains('1. David — 50 points\n'
            '2. Chloé — 115 points\n'
            '3. Bob — 140 points\n'
            '4. Alice — 101 points'),
      );

      // The home list's cards read `standingOf`, off the current game: it
      // must reach the same order, or a card would contradict the screen.
      await tester.runAsync(() async {
        final standing =
            await games.standingOf(games.currentGame!, gameType: type);
        expect([for (final p in standing.rankedPlayers) p.name],
            ['David', 'Chloé', 'Bob', 'Alice']);
        expect(standing.soleLeader?.name, 'David');
      });
    });

    testWidgets('open, the same game still ranks by the total',
        (tester) async {
      // Four rounds: Chloé and David are still in, so the game is not over.
      await tester
          .runAsync(() => anEliminationGame(finished: false, rounds: 4));
      await tester
          .pumpWidget(wrap(const StandingsScreen(boardBuilder: _board)));
      await tester.pumpAndSettle();

      expect(rowNames(tester), ['David', 'Chloé', 'Alice', 'Bob']);
      expect(_headline, findsNothing);
    });

    testWidgets('a race to a total with the same threshold ranks by the total',
        (tester) async {
      // The same game, of a type that ends when a player reaches 100 instead:
      // a threshold alone does not change the order (decided 2026-09-20).
      await tester.runAsync(() async {
        final type = await anEliminationGame(finished: true);
        await gameTypes.updateGameType(GameType(
          id: type.id,
          name: type.name,
          iconCodePoint: type.iconCodePoint,
          cardColorValue: type.cardColorValue,
          isLowestScoreWins: true,
          playerDeadConditionType: PlayerDeadConditionType.over,
          playerDeadThreshold: 100,
          gameOverConditionType: GameOverConditionType.firstPlayerOver,
          gameOverThreshold: 100,
        ));
      });
      await tester
          .pumpWidget(wrap(const StandingsScreen(boardBuilder: _board)));
      await tester.pumpAndSettle();

      expect(rowNames(tester), ['David', 'Alice', 'Chloé', 'Bob']);
      expect(find.text(l10n.gameEndWinner('David')), findsOneWidget);
    });
  });
}
