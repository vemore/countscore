// The board is one lane per player — header and cells in one column, the
// leader crowned — or, through the app-bar toggle, one row per player
// (wip/done/2026-09-18-board-hides-who-owns-each-column-and-who-leads.md).

import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game_analysis.dart';
import 'package:countscore/models/game_standing.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/providers/settings_provider.dart';
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

  Widget wrap({SettingsProvider? settings, Key? key}) {
    return MultiProvider(
      key: key,
      providers: [
        ChangeNotifierProvider<GameProvider>.value(value: games),
        ChangeNotifierProvider<GameTypeProvider>.value(value: gameTypes),
        ChangeNotifierProvider<BackendProvider>(
            create: (_) => BackendProvider(null)),
        ChangeNotifierProvider<GroupProvider>(
            create: (_) => GroupProvider(db: db, enableStream: false)),
        if (settings != null)
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
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

  /// Opens a board [width] logical pixels wide on a game with [names] and
  /// three rounds; the first one is scored with [firstRound] (7 each when
  /// null).
  Future<void> openBoard(
    WidgetTester tester,
    double width,
    List<String> names, {
    List<int>? firstRound,
    bool lowestWins = false,
    SettingsProvider? settings,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final id = await games.createGame('Partie', null, lowestWins, names, null);
    await games.loadGame(id);
    for (var i = 0; i < 3; i++) {
      await games.addRound();
    }
    final first = games.currentRounds.first;
    final players = games.currentPlayers;
    for (var i = 0; i < players.length; i++) {
      await games.updateScore(players[i].id!, first.id!, firstRound?[i] ?? 7);
    }
    await tester.pumpWidget(wrap(settings: settings));
    await tester.pumpAndSettle();
  }

  Player playerNamed(String name) =>
      games.currentPlayers.firstWhere((p) => p.name == name);

  Finder lane(String name) => find.byKey(Key('board_lane_${playerNamed(name).id}'));

  Finder crownIn(String name) => find.descendant(
      of: lane(name), matching: find.byKey(const Key('board_leader_crown')));

  ScrollPosition lanesScroll(WidgetTester tester) => tester
      .state<ScrollableState>(find.descendant(
          of: find.byKey(const Key('board_lanes_scroll')),
          matching: find.byType(Scrollable)))
      .position;

  group('the crown', () {
    testWidgets('is on the lowest total when the lowest score wins',
        (tester) async {
      await openBoard(tester, 400, ['Ann', 'Bob', 'Cid'],
          firstRound: [12, 3, 20], lowestWins: true);

      expect(find.byKey(const Key('board_leader_crown')), findsOneWidget);
      expect(crownIn('Bob'), findsOneWidget);
    });

    testWidgets('is on the highest total otherwise', (tester) async {
      await openBoard(tester, 400, ['Ann', 'Bob', 'Cid'],
          firstRound: [12, 3, 20]);

      expect(find.byKey(const Key('board_leader_crown')), findsOneWidget);
      expect(crownIn('Cid'), findsOneWidget);
      // Places under the totals, best first.
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
    });
  });

  // wip/done/2026-09-19-board-and-home-crown-a-tie.md: a tie for the lead
  // crowned the earlier seat.
  testWidgets('a round of equal scores crowns nobody; every place reads #1',
      (tester) async {
    await openBoard(tester, 400, ['Ann', 'Bob', 'Cid'], firstRound: [0, 0, 0]);

    expect(find.byKey(const Key('board_leader_crown')), findsNothing);
    expect(find.text('#1'), findsNWidgets(3));
    // No lane is outlined as the leader's.
    for (final name in ['Ann', 'Bob', 'Cid']) {
      final box = tester.widget<Container>(lane(name)).decoration!
          as BoxDecoration;
      expect((box.border! as Border).top.color, Colors.transparent,
          reason: name);
    }
  });

  testWidgets('rows: a tie for the lead crowns nobody and the ranking still '
      'sorts', (tester) async {
    await openBoard(tester, 400, ['Ann', 'Bob', 'Cid'], firstRound: [5, 9, 9]);
    await tester.tap(find.byKey(const Key('board_view_toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('board_leader_crown')), findsNothing);
    double rowY(String name) => tester
        .getTopLeft(find.byKey(Key('board_row_${playerNamed(name).id}')))
        .dy;
    await tester.tap(find.text('Ranking'));
    await tester.pumpAndSettle();
    expect(rowY('Bob'), lessThan(rowY('Cid')));
    expect(rowY('Cid'), lessThan(rowY('Ann')));
  });

  testWidgets('no crown before any score is entered', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final id = await games.createGame('Partie', null, false, ['A', 'B'], null);
    await games.loadGame(id);
    await games.addRound();
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('board_leader_crown')), findsNothing);
  });

  testWidgets('at 400 dp, 8 players fit with no horizontal scroll',
      (tester) async {
    final names = [for (var i = 1; i <= 8; i++) 'P$i'];
    await openBoard(tester, 400, names);

    expect(tester.takeException(), isNull);
    expect(lanesScroll(tester).maxScrollExtent, 0);
    for (final name in names) {
      expect(tester.getRect(lane(name)).right, lessThanOrEqualTo(400));
    }
    expect(find.byKey(const Key('board_ranking_ribbon')), findsNothing);
  });

  testWidgets(
      'at 400 dp, 10 players scroll sideways and keep the round column '
      'in view', (tester) async {
    final names = [for (var i = 1; i <= 10; i++) 'P$i'];
    await openBoard(tester, 400, names);

    expect(tester.takeException(), isNull);
    expect(lanesScroll(tester).maxScrollExtent, greaterThan(0));
    expect(find.byKey(const Key('board_ranking_ribbon')), findsOneWidget);

    final roundBefore = tester.getRect(find.byKey(const Key('board_round_1')));
    final firstLaneBefore = tester.getRect(lane('P1')).left;
    await tester.drag(
        find.byKey(const Key('board_lanes_scroll')), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(lanesScroll(tester).pixels, greaterThan(0));
    expect(tester.getRect(lane('P1')).left, lessThan(firstLaneBefore));
    final roundAfter = tester.getRect(find.byKey(const Key('board_round_1')));
    expect(roundAfter, roundBefore);
    expect(roundAfter.left, greaterThanOrEqualTo(0));
  });

  // wip/done/2026-09-19-board-does-not-scroll-past-eight-players.md: on the
  // PWA nothing moved the lanes, and Flutter drags a scroll view with a mouse
  // only when told to.
  for (final kind in [
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  ]) {
    testWidgets('at 400 dp, a ${kind.name} drag brings the 10th lane into view',
        (tester) async {
      final names = [for (var i = 1; i <= 10; i++) 'P$i'];
      await openBoard(tester, 400, names);
      expect(tester.getRect(lane('P10')).left, greaterThan(400));

      // Start on a cell, where the lanes' InkWells sit.
      final start = tester.getCenter(find.byKey(Key(
          'board_cell_${playerNamed('P3').id}_${games.currentRounds.first.id}')));
      if (kind == PointerDeviceKind.trackpad) {
        // A trackpad pans rather than drags.
        final gesture = await tester.createGesture(kind: kind);
        await gesture.panZoomStart(start);
        for (var i = 1; i <= 10; i++) {
          await gesture.panZoomUpdate(start, pan: Offset(-60.0 * i, 0));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.panZoomEnd();
      } else {
        await tester.dragFrom(start, const Offset(-600, 0), kind: kind);
      }
      await tester.pumpAndSettle();

      expect(lanesScroll(tester).pixels, greaterThan(0));
      final last = tester.getRect(lane('P10'));
      expect(last.left, lessThan(400));
      expect(last.right, lessThanOrEqualTo(400));
    });
  }

  testWidgets(
      'at 1400 dp, 10 players fit: no ribbon and no horizontal scroll',
      (tester) async {
    final names = [for (var i = 1; i <= 10; i++) 'P$i'];
    await openBoard(tester, 1400, names);

    expect(tester.takeException(), isNull);
    expect(lanesScroll(tester).maxScrollExtent, 0);
    expect(find.byKey(const Key('board_ranking_ribbon')), findsNothing);
    expect(tester.getRect(lane('P10')).right, lessThanOrEqualTo(1400));
  });

  for (final count in [4, 8, 10]) {
    testWidgets(
        'with $count players each header starts where its column starts',
        (tester) async {
      await openBoard(tester, 400, [for (var i = 1; i <= count; i++) 'P$i']);
      final firstRound = games.currentRounds.first;

      for (final p in games.currentPlayers) {
        final header = find.byKey(Key('board_lane_header_${p.id}'));
        final cell = find.byKey(Key('board_cell_${p.id}_${firstRound.id}'));
        expect(tester.getTopLeft(header).dx, tester.getTopLeft(cell).dx,
            reason: p.name);
        expect(tester.getSize(header).width, tester.getSize(cell).width);
      }
    });
  }

  testWidgets('on a wide screen the lanes stay readable and centred',
      (tester) async {
    await openBoard(tester, 1000, ['A', 'B', 'C']);

    expect(tester.takeException(), isNull);
    expect(lanesScroll(tester).maxScrollExtent, 0);
    final a = tester.getRect(lane('A'));
    final c = tester.getRect(lane('C'));
    expect(a.width, lessThanOrEqualTo(180));
    // Centred in what the round column leaves.
    expect((a.left - 46) - (1000 - 12 - c.right), moreOrLessEquals(0, epsilon: 1));
  });

  testWidgets(
      'the toggle switches to one row per player in seat order, and the '
      'choice survives rebuilding the app', (tester) async {
    final settings = SettingsProvider();
    await tester.runAsync(() => settings.ready);
    await openBoard(tester, 400, ['Zoe', 'Adam', 'Mia'],
        firstRound: [1, 30, 5], settings: settings);

    expect(find.byKey(const Key('board_rows_order')), findsNothing);
    await tester.tap(find.byKey(const Key('board_view_toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('board_rows_order')), findsOneWidget);
    double rowY(String name) => tester
        .getTopLeft(find.byKey(Key('board_row_${playerNamed(name).id}')))
        .dy;
    expect(rowY('Zoe'), lessThan(rowY('Adam')));
    expect(rowY('Adam'), lessThan(rowY('Mia')));

    // The ranking puts Adam first, Mia second.
    await tester.tap(find.text('Ranking'));
    await tester.pumpAndSettle();
    expect(rowY('Adam'), lessThan(rowY('Mia')));
    expect(rowY('Mia'), lessThan(rowY('Zoe')));

    // A new app — new providers — over the same SharedPreferences.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    expect(prefs!.getString(SettingsProvider.boardViewKey), 'rows');
    final reloaded = SettingsProvider();
    await tester.runAsync(() => reloaded.ready);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(wrap(settings: reloaded, key: UniqueKey()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('board_rows_order')), findsOneWidget);
    expect(rowY('Zoe'), lessThan(rowY('Adam')),
        reason: 'a new board opens in seat order');
  });

  // wip/done/2026-09-20-ranking-ignores-the-game-types-ranking-rule.md: the
  // badges read the standing, so they follow the type's ranking rule too.
  group('an elimination game', () {
    /// The reproduced ZapZap game of four, out above 100, five rounds: Alice
    /// out in round 1 with 101, Bob out in round 4 with 140, Chloé out in
    /// round 5 with 115, David alone at the end with 50.
    Future<void> openZapZap(WidgetTester tester,
        {required bool finished, int rounds = 5}) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      // No `builtinKey`: the database already seeds one zapzap row, and the
      // key is unique among the live ones.
      final typeId = await gameTypes.createGameType(GameType(
        name: 'ZapZap',
        iconCodePoint: Icons.bolt.codePoint,
        cardColorValue: 0xFFFFC107,
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
      await games.loadGame(id);
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
    }

    String badgeIn(WidgetTester tester, String name) => tester
        .widgetList<Text>(find.descendant(
            of: lane(name), matching: find.textContaining('#')))
        .first
        .data!;

    testWidgets('finished, the badges follow the elimination order',
        (tester) async {
      await openZapZap(tester, finished: true);

      // David alone at the end, then the others last-out first: Alice, out
      // after one hand, is last however low her total.
      expect(badgeIn(tester, 'David'), '#1');
      expect(badgeIn(tester, 'Chloé'), '#2');
      expect(badgeIn(tester, 'Bob'), '#3');
      expect(badgeIn(tester, 'Alice'), '#4');
    });

    testWidgets('open, the badges still follow the total', (tester) async {
      // Four rounds: Alice (101) and Bob (140) are out, Chloé (85) and David
      // (40) are still in, so the game is not over and the board stays up.
      // By total Alice is third, by elimination order she would be last.
      await openZapZap(tester, finished: false, rounds: 4);

      expect(badgeIn(tester, 'David'), '#1');
      expect(badgeIn(tester, 'Chloé'), '#2');
      expect(badgeIn(tester, 'Alice'), '#3');
      expect(badgeIn(tester, 'Bob'), '#4');
    });
  });

  test('places are shared on a tie and follow the winning direction', () {
    final players = [
      for (var i = 0; i < 4; i++)
        Player(id: i + 1, gameId: 1, name: 'P$i', orderIndex: i),
    ];
    final totals = {1: 10, 2: 30, 3: 10, 4: 5};
    expect(
      GameStanding(players: players, totals: totals, isLowestScoreWins: false)
          .ranks,
      {1: 2, 2: 1, 3: 2, 4: 4},
    );
    expect(
      GameStanding(players: players, totals: totals, isLowestScoreWins: true)
          .ranks,
      {1: 2, 2: 4, 3: 2, 4: 1},
    );
  });
}
