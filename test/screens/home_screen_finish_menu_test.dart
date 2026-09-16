// "Finish" is offered on the home screen under exactly the board's rule.
//
// A game with no round was never played, so there is nothing to declare over —
// and declaring one over used to count towards the Play review prompt, which
// made three empty games enough to satisfy a guard meant to mean "enough games
// to have an opinion". A finished game keeps the item, because reopening it is
// the same menu entry.
//
// The menu is read through its `itemBuilder` rather than by tapping it open:
// the test font draws every glyph as a full em-wide box, so any Material popup
// menu overflows its 256 px in a widget test whatever the strings say. The
// subject here is which entries the card builds, not how they lay out.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/screens/home_screen.dart';
import 'package:countscore/services/drift/database.dart';

void main() {
  late AppDatabase db;
  late GameProvider games;
  late GameTypeProvider gameTypes;

  setUp(() {
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
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en', ''), Locale('fr', '')],
        locale: Locale('en', ''),
        home: HomeScreen(),
      ),
    );
  }

  /// Pumps the screen past its post-frame load and returns the values of the
  /// only game card's overflow menu.
  Future<List<Object?>> menuOfTheOnlyGame(WidgetTester tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    final finder = find.byWidgetPredicate((w) => w is PopupMenuButton);
    expect(finder, findsOneWidget);
    final dynamic button = tester.widget(finder);
    final items = button.itemBuilder(tester.element(finder)) as List<dynamic>;
    return [
      for (final item in items)
        if (item is PopupMenuItem) item.value,
    ];
  }

  testWidgets('a game with no round is not offered "Finish"', (tester) async {
    await games.createGame('Partie', null, false, ['Alice', 'Bob'], null);

    final values = await menuOfTheOnlyGame(tester);

    expect(values, isNot(contains('finish_game')));
    // The rest of the menu is untouched.
    expect(values, containsAll(<String>['new_same', 'rename', 'delete']));
  });

  testWidgets('a game with a round is offered "Finish"', (tester) async {
    final id =
        await games.createGame('Partie', null, false, ['Alice', 'Bob'], null);
    await games.loadGame(id);
    await games.addRound();
    await games.loadGames();

    final values = await menuOfTheOnlyGame(tester);

    expect(values, contains('finish_game'));
  });

  testWidgets('a finished game is offered the entry whatever its rounds',
      (tester) async {
    final id =
        await games.createGame('Partie', null, false, ['Alice', 'Bob'], null);
    await games.setGameFinished(id, true);

    final values = await menuOfTheOnlyGame(tester);

    expect(values, contains('finish_game'),
        reason: 'a game wrongly finished before this fix must stay reopenable');
  });
}
