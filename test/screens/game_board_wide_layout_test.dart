// Above 600 dp the board's score grid spreads over the available width; below,
// it keeps the phone layout it always had: intrinsic columns in a grid that
// scrolls both ways (wip/done/2026-09-16-no-large-screen-layout.md).

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game_analysis.dart';
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

  /// Opens a board [width] logical pixels wide on a game with [names] and
  /// three rounds, the first one scored.
  Future<void> openBoard(
      WidgetTester tester, double width, List<String> names) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final id = await games.createGame('Partie', null, false, names, null);
    await games.loadGame(id);
    for (var i = 0; i < 3; i++) {
      await games.addRound();
    }
    final first = games.currentRounds.first;
    for (final p in games.currentPlayers) {
      await games.updateScore(p.id!, first.id!, 7);
    }
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
  }

  Finder grid() => find.byKey(const Key('board_score_grid'));
  DataTable table(WidgetTester tester) => tester.widget<DataTable>(grid());

  test('the breakpoint sits at 600 dp', () {
    expect(isBoardGridWide(599.9), isFalse);
    expect(isBoardGridWide(600), isTrue);
  });

  testWidgets('at 400 dp the grid keeps its intrinsic phone layout',
      (tester) async {
    await openBoard(tester, 400, ['A', 'B', 'C']);

    expect(tester.takeException(), isNull);
    expect(tester.getSize(grid()).width, lessThan(400));
    expect(table(tester).columns.map((c) => c.columnWidth),
        everyElement(isNull));
  });

  testWidgets('at 400 dp a grid wider than the screen still scrolls sideways',
      (tester) async {
    await openBoard(tester, 400, [for (var i = 1; i <= 8; i++) 'Player $i']);

    expect(tester.takeException(), isNull);
    expect(tester.getSize(grid()).width, greaterThan(400));
  });

  testWidgets('at 1000 dp the grid spreads over the width', (tester) async {
    await openBoard(tester, 1000, ['A', 'B', 'C']);

    expect(tester.takeException(), isNull);
    expect(tester.getSize(grid()).width, 1000);
    final columns = table(tester).columns;
    expect(columns.first.columnWidth, isNull,
        reason: 'the round column keeps its intrinsic width');
    expect(columns.skip(1).map((c) => c.columnWidth),
        everyElement(isA<IntrinsicColumnWidth>()));

    // The three player columns share the room equally, and each is far wider
    // than the one-letter name and the score it holds.
    final xs = [
      for (final name in ['A', 'B', 'C'])
        tester.getTopLeft(find.text(name)).dx,
    ];
    final step = xs[1] - xs[0];
    expect(xs[2] - xs[1], moreOrLessEquals(step, epsilon: 1));
    expect(step, greaterThan(200));
  });

  testWidgets(
      'at 1000 dp many players overflow into a sideways scroll, '
      'not off the screen', (tester) async {
    await openBoard(tester, 1000, [for (var i = 1; i <= 12; i++) 'Player $i']);

    expect(tester.takeException(), isNull);
    expect(tester.getSize(grid()).width, greaterThan(1000));
  });
}
