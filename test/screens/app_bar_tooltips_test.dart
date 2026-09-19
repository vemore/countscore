// The two app-bar icons that had no name — statistics on the home screen,
// the leaderboard on the board — are found by their tooltip, which is also what
// a screen reader announces, in English and in French.
// wip/done/2026-09-19-app-bar-icon-buttons-have-no-label.md

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

/// The board asks on open whether this game has a stored analysis; the
/// default reaches the real database.
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

  Widget wrap(Widget home, Locale locale) {
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
        supportedLocales: const [Locale('en'), Locale('fr')],
        locale: locale,
        home: home,
      ),
    );
  }

  for (final (locale, statistics, ranking) in [
    (const Locale('en'), 'Player Statistics', 'Ranking'),
    (const Locale('fr'), 'Statistiques des joueurs', 'Classement'),
  ]) {
    testWidgets('home: the statistics icon is named ($locale)',
        (tester) async {
      await tester.pumpWidget(wrap(const HomeScreen(), locale));
      await tester.pumpAndSettle();

      final button = find.byTooltip(statistics);
      expect(button, findsOneWidget);
      expect(
        find.descendant(of: button, matching: find.byIcon(Icons.bar_chart)),
        findsOneWidget,
      );
    });

    testWidgets('board: the leaderboard icon is named ($locale)',
        (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final id =
          await games.createGame('Partie', null, true, ['Ann', 'Bob'], null);
      await games.loadGame(id);

      await tester.pumpWidget(
          wrap(GameBoardScreen(analysisRepo: _NoAnalysis()), locale));
      await tester.pumpAndSettle();

      final button = find.byTooltip(ranking);
      expect(button, findsOneWidget);
      expect(
        find.descendant(of: button, matching: find.byIcon(Icons.leaderboard)),
        findsOneWidget,
      );
    });
  }
}
