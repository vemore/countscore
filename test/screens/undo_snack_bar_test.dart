// Reopening a finished game offers it back through an Undo snackbar, on the
// home screen and on the board. Flutter keeps a snackbar that has an action on
// screen until it is dismissed, so both used to stay up indefinitely
// (wip/done/2026-09-19-undo-snackbar-never-goes-away.md): an Undo still offered
// long after the action is misleading. Each now goes away on its own after
// kUndoSnackBarDuration.
//
// The menus are driven through their `onSelected` rather than by tapping them
// open, for the reason home_screen_finish_menu_test.dart gives: the test font
// overflows any Material popup menu.

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
import 'package:countscore/screens/home_screen.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/utils/undo_snack_bar.dart';

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

  /// A finished game with one round, loaded as the current game.
  Future<int> finishedGame() async {
    final id =
        await games.createGame('Partie', null, false, ['Alice', 'Bob'], null);
    await games.loadGame(id);
    await games.addRound();
    await games.setGameFinished(id, true);
    await games.loadGames();
    await games.loadGame(id);
    return id;
  }

  /// Picks [value] from the only popup menu on screen.
  Future<void> select(WidgetTester tester, String value) async {
    final finder = find.byWidgetPredicate((w) => w is PopupMenuButton);
    expect(finder, findsOneWidget);
    final dynamic button = tester.widget(finder);
    await tester.runAsync(() async {
      await button.onSelected(value);
    });
    await tester.pump();
  }

  /// The reopen snackbar is up with its Undo, then gone once its duration has
  /// run out with nothing touched — and the game stays reopened.
  Future<void> expectExpires(WidgetTester tester, int gameId) async {
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Undo'), findsOneWidget);
    final bar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(bar.persist, isFalse);
    expect(bar.duration, kUndoSnackBarDuration);

    await tester.pump(kUndoSnackBarDuration);
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    await tester.runAsync(games.loadGames);
    expect(games.games.firstWhere((g) => g.id == gameId).isFinished, isFalse);
  }

  testWidgets('the home screen\'s reopen Undo goes away on its own',
      (tester) async {
    final id = await finishedGame();
    await tester.pumpWidget(wrap(const HomeScreen()));
    await tester.pumpAndSettle();

    await select(tester, 'finish_game');

    await expectExpires(tester, id);
  });

  testWidgets('the board\'s reopen Undo goes away on its own', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final id = await finishedGame();
    await tester.pumpWidget(wrap(GameBoardScreen(analysisRepo: _NoAnalysis())));
    await tester.pumpAndSettle();

    await select(tester, 'finish_game');

    await expectExpires(tester, id);
  });
}
