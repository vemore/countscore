// "Who starts?" in the board's overflow menu draws one of the game's players
// at random and shows the name — nothing stored, nothing sent.
//
// The menu is read through its `itemBuilder` and driven through `onSelected`
// rather than tapped open: the test font draws every glyph as a full em-wide
// box, so any Material popup menu overflows its 256 px in a widget test
// (`home_screen_finish_menu_test.dart` says the same).

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

  Future<void> openBoard(WidgetTester tester, List<String> names) async {
    final id = await games.createGame('Partie', null, false, names, null);
    await games.loadGame(id);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
  }

  Future<void> openWhoStarts(WidgetTester tester) async {
    final finder = find.byType(PopupMenuButton<String>);
    expect(finder, findsOneWidget);
    final button = tester.widget<PopupMenuButton<String>>(finder);
    final values = [
      for (final item in button.itemBuilder(tester.element(finder)))
        if (item is PopupMenuItem<String>) item.value,
    ];
    expect(values, contains('who_starts'));
    button.onSelected!('who_starts');
    await tester.pumpAndSettle();
  }

  String chosen(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('who_starts_name'))).data!;

  const names = ['Alice', 'Bob', 'Chloé', 'David', 'Emma'];

  testWidgets("draws one of the game's N players, and draws again",
      (tester) async {
    await openBoard(tester, names);

    await openWhoStarts(tester);
    expect(find.text(l10n.whoStarts), findsOneWidget);
    expect(names, contains(chosen(tester)));

    final seen = <String>{};
    for (var i = 0; i < 40; i++) {
      await tester.tap(find.byKey(const Key('who_starts_again')));
      await tester.pump();
      final name = chosen(tester);
      expect(names, contains(name));
      seen.add(name);
    }
    expect(seen.length, greaterThan(1),
        reason: 'forty draws among five players are not all the same');

    await tester.tap(find.text(l10n.close));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('who_starts_name')), findsNothing);
  });

  testWidgets('a single player is always the one who starts', (tester) async {
    await openBoard(tester, ['Alice']);

    await openWhoStarts(tester);
    expect(chosen(tester), 'Alice');
    expect(find.byKey(const Key('who_starts_again')), findsNothing);
  });
}
