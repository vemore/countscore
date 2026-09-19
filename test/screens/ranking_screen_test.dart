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
  /// round scored, loaded as current. Chloé is seated with her own colour.
  Future<void> anOpenGame({
    required bool lowestWins,
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

    // Every player in the colour the board gives them.
    final colours = playerColorsById(games.currentPlayers);
    for (final player in games.currentPlayers) {
      final avatar = tester.widget<PlayerAvatar>(find.byWidgetPredicate(
          (w) => w is PlayerAvatar && w.name == player.name));
      expect(avatar.color, colours[player.id], reason: player.name);
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
}
