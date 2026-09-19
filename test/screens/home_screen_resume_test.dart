// The home screen's Resume card: the most recently played open game, with its
// leader, one tap from its board — and no card at all once every game is over.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game.dart';
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/screens/home_screen.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/utils/app_theme.dart';
import 'package:countscore/utils/player_colors.dart';
import 'package:countscore/widgets/player_avatars.dart';

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

  Widget wrap({Brightness brightness = Brightness.light}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GameProvider>.value(value: games),
        ChangeNotifierProvider<GameTypeProvider>.value(value: gameTypes),
      ],
      child: MaterialApp(
        theme: buildAppTheme(brightness),
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

  /// Creates a game with one scored round; returns its id.
  Future<int> playedGame(String name, Map<String, int> scores) async {
    final id = await games.createGame(
        name, null, false, scores.keys.toList(), null);
    await games.loadGame(id);
    await games.addRound();
    final round = games.currentRounds.last;
    for (final player in games.currentPlayers) {
      await games.updateScore(player.id!, round.id!, scores[player.name]!);
    }
    await games.loadGames();
    return id;
  }

  Future<void> pumpHome(WidgetTester tester,
      {Brightness brightness = Brightness.light}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(brightness: brightness));
    await tester.pumpAndSettle();
  }

  testWidgets('the Resume card shows the latest open game and its leader',
      (tester) async {
    await tester.runAsync(() async {
      await playedGame('Old evening', {'Alice': 10, 'Bob': 3});
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await playedGame('Tonight', {'Thibaut': 31, 'Vincent': 12});
    });

    await pumpHome(tester);
    await tester.runAsync(() => Future<void>.delayed(
        const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    final hero = find.byKey(const Key('resumeHero'));
    expect(hero, findsOneWidget);
    expect(find.descendant(of: hero, matching: find.text('Tonight')),
        findsOneWidget);
    expect(find.descendant(of: hero, matching: find.text('Thibaut leads · 31')),
        findsOneWidget);
    expect(find.descendant(of: hero, matching: find.text('Resume')),
        findsOneWidget);
    // The other open game is listed below, with its state.
    expect(find.text('Old evening'), findsOneWidget);
    expect(find.byKey(const Key('statusInProgress')), findsOneWidget);
  });

  testWidgets('the Resume card draws the players as the board does: two '
      'letters, the board colours, each disc ringed apart from the card',
      (tester) async {
    await tester.runAsync(() async {
      await playedGame('Tarot',
          {'Lionel': 10, 'Laurent': 20, 'Thibaut': 30, 'Vincent': 40});
    });

    await pumpHome(tester);
    await tester.runAsync(() => Future<void>.delayed(
        const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    final stack = find.byKey(const Key('resumeHeroAvatars'));
    for (final initials in ['Li', 'La', 'Th', 'Vi']) {
      expect(find.descendant(of: stack, matching: find.text(initials)),
          findsOneWidget, reason: initials);
    }
    final board = playerColorsById(games.currentPlayers);
    final avatars = tester
        .widgetList<PlayerAvatar>(
            find.descendant(of: stack, matching: find.byType(PlayerAvatar)))
        .toList();
    expect(avatars.map((a) => a.color),
        [for (final p in games.currentPlayers) board[p.id]]);
    // The ring is the hero's text colour, not its teal: a cyan or teal
    // player's disc stays visible on it.
    final scheme = buildAppTheme(Brightness.light).colorScheme;
    expect(avatars.map((a) => a.borderColor).toSet(), {scheme.onPrimary});
  });

  testWidgets('a lowest-score game is led by the lowest total',
      (tester) async {
    await tester.runAsync(() async {
      final id = await games.createGame(
          'Skyjo', null, true, ['Laurent', 'Vincent'], null);
      await games.loadGame(id);
      await games.addRound();
      final round = games.currentRounds.last;
      await games.updateScore(games.currentPlayers[0].id!, round.id!, 40);
      await games.updateScore(games.currentPlayers[1].id!, round.id!, 12);
      await games.loadGames();
    });

    await pumpHome(tester);
    await tester.runAsync(() => Future<void>.delayed(
        const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text('Vincent leads · 12'), findsOneWidget);
  });

  testWidgets('no Resume card when every game is finished; the winner is shown',
      (tester) async {
    await tester.runAsync(() async {
      final id = await playedGame('Done', {'Alice': 10, 'Bob': 30});
      await games.setGameFinished(id, true);
    });

    await pumpHome(tester, brightness: Brightness.dark);
    await tester.runAsync(() => Future<void>.delayed(
        const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('resumeHero')), findsNothing);
    expect(find.text('Done'), findsOneWidget);
    final pill = find.byKey(const Key('statusFinished'));
    expect(pill, findsOneWidget);
    expect(find.descendant(of: pill, matching: find.text('Bob')),
        findsOneWidget);
  });

  testWidgets('a finished tie names no single winner: the flag, "Finished", '
      'every tied player in the tooltip', (tester) async {
    await tester.runAsync(() async {
      final id =
          await playedGame('Draw', {'Alice': 20, 'Bob': 20, 'Chloé': 5});
      await games.setGameFinished(id, true);
    });

    await pumpHome(tester);
    await tester.runAsync(() => Future<void>.delayed(
        const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    final pill = find.byKey(const Key('statusFinished'));
    expect(pill, findsOneWidget);
    expect(find.descendant(of: pill, matching: find.text('Finished')),
        findsOneWidget);
    for (final name in ['Alice', 'Bob']) {
      expect(find.descendant(of: pill, matching: find.text(name)),
          findsNothing, reason: name);
    }
    expect(
        find.descendant(
            of: pill, matching: find.byIcon(Icons.emoji_events_outlined)),
        findsNothing);
    expect(find.descendant(of: pill, matching: find.byIcon(Icons.flag_outlined)),
        findsOneWidget);
    expect(find.byTooltip('Tie: Alice, Bob'), findsOneWidget);
    expect(find.textContaining('Won by'), findsNothing);
  });

  testWidgets('an open game tied for the lead names no leader on the Resume '
      'card', (tester) async {
    await tester.runAsync(() async {
      await playedGame('Level', {'Alice': 0, 'Bob': 0});
    });

    await pumpHome(tester);
    await tester.runAsync(() => Future<void>.delayed(
        const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('resumeHero')), findsOneWidget);
    expect(find.byKey(const Key('resumeHeroLeader')), findsNothing);
    expect(find.textContaining('leads'), findsNothing);
  });

  test('resumableGame picks the open game played last', () {
    final now = DateTime(2026, 9, 18, 21);
    final older = Game(
        name: 'older',
        isLowestScoreWins: false,
        createdAt: now.subtract(const Duration(days: 2)),
        lastModified: now);
    final newer = Game(
        name: 'newer',
        isLowestScoreWins: false,
        createdAt: now.subtract(const Duration(hours: 1)));
    final finished = Game(
        name: 'finished',
        isLowestScoreWins: false,
        createdAt: now,
        lastModified: now.add(const Duration(minutes: 5)),
        finishedAt: now.add(const Duration(minutes: 5)));

    // Played an hour after the newer one was created: it is the one to resume.
    expect(resumableGame([finished, newer, older]), same(older));
    expect(resumableGame([finished]), isNull);
    expect(resumableGame(const []), isNull);
  });
}
