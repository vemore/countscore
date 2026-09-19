// The home screen's card grid: one column of game cards on a phone, several
// side by side past kHomeGridBreakpoint, with the Resume card across the
// full width either way.

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
import 'package:countscore/utils/app_theme.dart';

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
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        locale: const Locale('en', ''),
        home: const HomeScreen(),
      ),
    );
  }

  Future<void> seed(List<String> finished, {String winner = 'Alice'}) =>
      seedGames(games, finished, winner);

  Future<void> pumpAt(WidgetTester tester, double widthDp) async {
    tester.view.physicalSize = Size(widthDp, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }

  Rect cardOf(WidgetTester tester, String name) => tester.getRect(
      find.ancestor(of: find.text(name), matching: find.byType(Card)));

  test('the breakpoint is 600 dp, and the grid never has one column', () {
    expect(kHomeGridBreakpoint, 600);
    expect(homeGridColumns(400), 1);
    expect(homeGridColumns(599), 1);
    expect(homeGridColumns(600), 2);
    expect(homeGridColumns(1200), 3);
    expect(homeGridColumns(1600), 4);
  });

  testWidgets('at 400 dp the game cards are one full-width column',
      (tester) async {
    await tester.runAsync(() => seed(['Game A', 'Game B', 'Game C']));
    await pumpAt(tester, 400);

    final cards = [
      for (final name in ['Game A', 'Game B', 'Game C']) cardOf(tester, name)
    ]..sort((a, b) => a.top.compareTo(b.top));
    for (var i = 0; i < cards.length; i++) {
      expect(cards[i].left, 16);
      expect(cards[i].width, 400 - 32);
      if (i > 0) expect(cards[i].top, greaterThan(cards[i - 1].bottom));
    }
    expect(tester.getSize(find.byKey(const Key('resumeHero'))).width,
        400 - 32);
  });

  testWidgets('at 1200 dp the game cards sit side by side, under a '
      'full-width Resume card', (tester) async {
    await tester.runAsync(
        () => seed(['Game A', 'Game B', 'Game C', 'Game D']));
    await pumpAt(tester, 1200);

    final hero = tester.getRect(find.byKey(const Key('resumeHero')));
    expect(hero.width, 1200 - 32);

    final cards = [
      for (final name in ['Game A', 'Game B', 'Game C', 'Game D'])
        cardOf(tester, name)
    ]..sort((a, b) => a.top.compareTo(b.top));
    // Three columns: the first row shares a top, the fourth card wraps.
    final firstRow = cards.where((r) => r.top == cards.first.top).toList();
    expect(firstRow, hasLength(3));
    expect(firstRow.map((r) => r.left).toSet(), hasLength(3));
    for (final r in firstRow) {
      expect(r.top, greaterThan(hero.bottom));
      expect(r.width, closeTo((1200 - 32 - 2 * 12) / 3, 0.01));
    }
    final wrapped = cards.singleWhere((r) => r.top != cards.first.top);
    expect(wrapped.top, greaterThan(firstRow.first.bottom));
    expect(wrapped.left, 16);
  });

  testWidgets('at 600 dp two narrow cards with long names do not overflow',
      (tester) async {
    await tester.runAsync(() => seed(
        ['A very long game name for a narrow card', 'Another long one'],
        winner: 'Maximilienne-Alexandrine'));
    await pumpAt(tester, 600);

    expect(tester.takeException(), isNull);
    final a = cardOf(tester, 'A very long game name for a narrow card');
    final b = cardOf(tester, 'Another long one');
    expect(a.top, b.top);
    expect(a.left, isNot(b.left));
    // Too narrow for the pill beside the name: it sits under it, in the card.
    for (final name in [
      'A very long game name for a narrow card',
      'Another long one'
    ]) {
      final card =
          find.ancestor(of: find.text(name), matching: find.byType(Card));
      final pill = tester.getRect(find.descendant(
          of: card, matching: find.byKey(const Key('statusFinished'))));
      expect(pill.top, greaterThan(tester.getRect(find.text(name)).bottom));
      expect(tester.getRect(card).contains(pill.bottomRight - const Offset(1, 1)),
          isTrue);
    }
  });

  testWidgets('no width from 320 to 1600 dp overflows a card',
      (tester) async {
    await tester.runAsync(() => seed(['A long game name', 'Another', 'Third'],
        winner: 'Maximilienne-Alexandrine'));
    await pumpAt(tester, 320);
    for (var width = 320.0; width <= 1600; width += 20) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$width dp');
    }
  });
}

/// One open game (the Resume card) and [finished] finished ones, each with a
/// scored round, so every card carries a winner pill.
Future<void> seedGames(
    GameProvider games, List<String> finished, String winner) async {
  Future<int> played(String name) async {
    final id =
        await games.createGame(name, null, false, [winner, 'Bob'], null);
    await games.loadGame(id);
    await games.addRound();
    final round = games.currentRounds.last;
    for (final player in games.currentPlayers) {
      await games.updateScore(
          player.id!, round.id!, player.name == winner ? 30 : 10);
    }
    return id;
  }

  for (final name in finished) {
    final id = await played(name);
    await games.setGameFinished(id, true);
  }
  await played('Tonight');
  await games.loadGames();
}
