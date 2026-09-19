// The in-game ranking, from the board's leaderboard button: the same podium
// and ranked rows as the end screen (`RankedPlayers`), in the players' board
// colours, the leader crowned, totals near the elimination threshold in
// orange and eliminated players struck out. "Play again" is covered in
// `play_again_test.dart`.
//
// Writes run on a real in-memory database, so they go through `runAsync`, as
// in `game_end_screen_test.dart`.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/screens/game_end_screen.dart';
import 'package:countscore/screens/ranking_screen.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/utils/player_colors.dart';
import 'package:countscore/widgets/board_lanes.dart';
import 'package:countscore/widgets/player_avatars.dart';

Widget _board(BuildContext context) => const Scaffold(body: Text('board'));

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

  Widget wrap(Widget home) {
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
        home: home,
      ),
    );
  }

  /// An open game of five of a type that puts a player out over 100, one
  /// round scored — none with [playRound] false — loaded as current. Chloé is
  /// seated with her own colour.
  Future<void> anOpenGame({
    required bool lowestWins,
    bool playRound = true,
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
    if (!playRound) return;
    await games.addRound();
    final round = games.currentRounds.single.id!;
    for (final p in games.currentPlayers) {
      await games.updateScore(p.id!, round, scores[p.name]!);
    }
    await games.loadGame(id);
  }

  /// The names as the screen ranks them: podium places 1, 2, 3, then the
  /// rows from top to bottom.
  List<String> rankedNames(WidgetTester tester) {
    final podium = [
      for (var place = 0; place < 3; place++)
        find.byKey(Key('ranking_podium_$place')),
    ];
    String nameIn(Finder scope) => tester
        .widgetList<PlayerAvatar>(
            find.descendant(of: scope, matching: find.byType(PlayerAvatar)))
        .single
        .name;
    final rows = find.byWidgetPredicate(
        (w) => w.key is ValueKey<String> &&
            (w.key as ValueKey<String>).value.startsWith('ranking_row_'));
    final rowList = rows.evaluate().toList()
      ..sort((a, b) => tester
          .getTopLeft(find.byWidget(a.widget))
          .dy
          .compareTo(tester.getTopLeft(find.byWidget(b.widget)).dy));
    return [
      for (final step in podium) nameIn(step),
      for (final row in rowList) nameIn(find.byWidget(row.widget)),
    ];
  }

  testWidgets('an open game: board colours, the leader crowned, no banner',
      (tester) async {
    await tester.runAsync(() => anOpenGame(lowestWins: true));
    await tester.pumpWidget(wrap(const RankingScreen(boardBuilder: _board)));
    await tester.pumpAndSettle();

    // Every player in the colour the board gives them, and with the board's
    // two letters, podium and rows alike.
    final colours = playerColorsById(games.currentPlayers);
    for (final player in games.currentPlayers) {
      final avatar = tester.widget<PlayerAvatar>(find.byWidgetPredicate(
          (w) => w is PlayerAvatar && w.name == player.name));
      expect(avatar.color, colours[player.id], reason: player.name);
      expect(find.text(player.name.substring(0, 2)), findsOneWidget,
          reason: player.name);
    }
    expect(
      tester
          .widget<PlayerAvatar>(find.byWidgetPredicate(
              (w) => w is PlayerAvatar && w.name == 'Chloé'))
          .color,
      const Color(0xFF00FF00),
    );

    // One crown, on the leader: Dora, lowest total.
    expect(find.byType(BoardCrown), findsOneWidget);
    final first = find.byKey(const Key('ranking_podium_0'));
    expect(find.descendant(of: first, matching: find.byType(BoardCrown)),
        findsOneWidget);
    expect(find.descendant(of: first, matching: find.text('Dora')),
        findsOneWidget);

    // The win rule is one line under the title.
    expect(find.byKey(const Key('ranking_summary')), findsOneWidget);
    expect(find.textContaining(l10n.gameEndLowestWins), findsOneWidget);
    expect(find.byKey(const Key('ranking_play_again')), findsOneWidget);
  });

  testWidgets('a highest-wins game is shared in the order the screen draws',
      (tester) async {
    await tester.runAsync(() => anOpenGame(lowestWins: false));
    String? shared;
    await tester.pumpWidget(wrap(RankingScreen(
      boardBuilder: _board,
      share: (text, {subject}) async => shared = text,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('share_result')));
    await tester.pumpAndSettle();

    expect(rankedNames(tester), ['Eve', 'Chloé', 'Alice', 'Bob', 'Dora']);
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

  testWidgets('near the threshold in orange, eliminated players struck out',
      (tester) async {
    await tester.runAsync(() => anOpenGame(lowestWins: true, scores: {
          'Alice': 30,
          'Bob': 20,
          'Chloé': 85,
          'Dora': 10,
          'Eve': 120,
        }));
    await tester.pumpWidget(wrap(const RankingScreen(boardBuilder: _board)));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(RankingScreen));
    final chloeTotal = tester.widget<Text>(find.text('85'));
    expect(chloeTotal.style?.color, boardWarningColor(context));
    final bobTotal = tester.widget<Text>(find.text('20'));
    expect(bobTotal.style?.color, isNot(boardWarningColor(context)));

    final eve = tester.widget<Text>(find.text('Eve'));
    expect(eve.style?.decoration, TextDecoration.lineThrough);
    expect(
        find.ancestor(of: find.text('Eve'), matching: find.byType(Opacity)),
        findsOneWidget);
    final alice = tester.widget<Text>(find.text('Alice'));
    expect(alice.style?.decoration, isNot(TextDecoration.lineThrough));
  });

  for (final (lowestWins, expected) in [
    (true, ['Dora', 'Bob', 'Alice', 'Chloé', 'Eve']),
    (false, ['Eve', 'Chloé', 'Alice', 'Bob', 'Dora']),
  ]) {
    testWidgets(
        '${lowestWins ? 'lowest' : 'highest'} wins: the ranks match the end '
        "screen's", (tester) async {
      await tester.runAsync(() => anOpenGame(lowestWins: lowestWins));

      await tester.pumpWidget(wrap(const RankingScreen(boardBuilder: _board)));
      await tester.pumpAndSettle();
      final ranking = rankedNames(tester);
      expect(ranking, expected);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      await tester.pumpWidget(wrap(const GameEndScreen(boardBuilder: _board)));
      await tester.pumpAndSettle();
      expect(rankedNames(tester), ranking);
    });
  }

  group('no crown without a sole leader', () {
    Future<void> expectNoCrownOnEitherScreen(WidgetTester tester) async {
      await tester.pumpWidget(wrap(const RankingScreen(boardBuilder: _board)));
      await tester.pumpAndSettle();
      expect(find.byType(BoardCrown), findsNothing, reason: 'ranking');

      await tester.pumpWidget(wrap(const GameEndScreen(boardBuilder: _board)));
      await tester.pumpAndSettle();
      expect(find.byType(BoardCrown), findsNothing, reason: 'end screen');
    }

    testWidgets('a game with no round played', (tester) async {
      await tester.runAsync(
          () => anOpenGame(lowestWins: true, playRound: false));
      await expectNoCrownOnEitherScreen(tester);
    });

    testWidgets('one round of all zeros', (tester) async {
      await tester.runAsync(() => anOpenGame(lowestWins: true, scores: {
            'Alice': 0,
            'Bob': 0,
            'Chloé': 0,
            'Dora': 0,
            'Eve': 0,
          }));
      await expectNoCrownOnEitherScreen(tester);
    });
  });

  testWidgets('a tie shares a place: no crown, the same step, the same number',
      (tester) async {
    // Alice and Dora tie for the lead, Bob and Chloé for fourth.
    await tester.runAsync(() => anOpenGame(lowestWins: true, scores: {
          'Alice': 10,
          'Bob': 40,
          'Chloé': 40,
          'Dora': 10,
          'Eve': 30,
        }));

    for (final screen in const [
      RankingScreen(boardBuilder: _board),
      GameEndScreen(boardBuilder: _board),
    ]) {
      await tester.pumpWidget(wrap(screen));
      await tester.pumpAndSettle();
      final reason = screen.runtimeType.toString();

      expect(find.byType(BoardCrown), findsNothing, reason: reason);
      // Seat order within the tie, then Eve alone on the third step.
      expect(rankedNames(tester), ['Alice', 'Dora', 'Eve', 'Bob', 'Chloé'],
          reason: reason);

      int idOf(String name) =>
          games.currentPlayers.firstWhere((p) => p.name == name).id!;
      double stepOf(String name) =>
          tester.getSize(find.byKey(Key('ranking_step_${idOf(name)}'))).height;
      expect(stepOf('Alice'), stepOf('Dora'), reason: reason);
      expect(stepOf('Eve'), lessThan(stepOf('Alice')), reason: reason);

      // The rows past the podium share place 4.
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
}
