// "Play again": the next game of the evening without the creation flow, from
// the standings of a finished game and from its menu on the home screen.
//
// Same type, same win rule, same players in the same order, opened on its
// board — and the game it was started from is left exactly as it was.
//
// The board is injected (`boardBuilder`): the real `GameBoardScreen` reaches
// the `AppDatabase` singleton. The home menu is read through its `itemBuilder`
// and fired through its `onSelected`, for the reason given in
// `home_screen_finish_menu_test.dart`: a Material popup overflows in a widget
// test whatever the strings say.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/providers/backend_provider.dart';
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/providers/group_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/screens/home_screen.dart';
import 'package:countscore/screens/standings_screen.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/utils/play_again.dart';

const _boardKey = Key('test_board');

Widget _board(BuildContext context) =>
    const Scaffold(key: _boardKey, body: Text('board'));

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

  /// A finished game of a custom, highest-wins type, three players seated
  /// Chloé, Alice, Bob, one round scored. Returns the game as stored.
  Future<Game> aFinishedGame({String name = 'Skyjo 3'}) async {
    final typeId = await gameTypes.createGameType(GameType(
      name: 'Belote du jeudi',
      iconCodePoint: Icons.casino.codePoint,
      cardColorValue: Colors.blue.toARGB32(),
      isLowestScoreWins: false,
    ));
    final id = await games.createGame(
      name,
      typeId,
      false,
      ['Chloé', 'Alice', 'Bob'],
      {'Chloé': 0xFF00FF00, 'Alice': null, 'Bob': 0xFFFF0000},
    );
    await games.loadGame(id);
    await games.addRound();
    await games.updateScore(
        games.currentPlayers.first.id!, games.currentRounds.single.id!, 12);
    await games.setGameFinished(id, true);
    await games.loadGames();
    await games.loadGame(id);
    return games.currentGame!;
  }

  /// The one game that is not [source], after checking there are two.
  Future<Game> theNewGame(Game source) async {
    await games.loadGames();
    expect(games.games, hasLength(2));
    return games.games.singleWhere((g) => g.id != source.id);
  }

  Future<void> expectSameSetUp(Game source, Game copy) async {
    expect(copy.gameTypeId, source.gameTypeId);
    expect(copy.isLowestScoreWins, source.isLowestScoreWins);
    expect(copy.isFinished, isFalse);
    expect(copy.name, 'Skyjo 4');
    final players = await games.getPlayersOfGame(copy.id!);
    expect(players.map((p) => p.name), ['Chloé', 'Alice', 'Bob']);
    expect(players.map((p) => p.colorValue), [0xFF00FF00, null, 0xFFFF0000]);
    expect(games.roundCountOf(copy.id!), 0);
  }

  Future<void> expectUnchanged(Game source) async {
    final players = await games.getPlayersOfGame(source.id!);
    expect(players.map((p) => p.name), ['Chloé', 'Alice', 'Bob']);
    expect(games.roundCountOf(source.id!), 1);
    final stored = games.games.singleWhere((g) => g.id == source.id);
    expect(stored.name, source.name);
    expect(stored.isFinished, isTrue);
    expect(stored.gameTypeId, source.gameTypeId);
  }

  testWidgets('the standings offer Play again, which opens the new game',
      (tester) async {
    final source = await tester.runAsync(aFinishedGame);

    await tester.pumpWidget(wrap(const StandingsScreen(boardBuilder: _board)));
    await tester.pumpAndSettle();
    expect(find.text('Play again'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('game_end_play_again')));
      // The writes run on the real database; let them land.
      for (var i = 0; i < 20 && find.byKey(_boardKey).evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();

    expect(find.byKey(_boardKey), findsOneWidget);
    await tester.runAsync(() async {
      final copy = await theNewGame(source!);
      expect(games.currentGame?.id, copy.id, reason: 'the board is the new game');
      await expectSameSetUp(source, copy);
      await expectUnchanged(source);
    });
  });

  group('home menu', () {
    Future<dynamic> menuButton(WidgetTester tester) async {
      await tester.pumpWidget(wrap(const HomeScreen(boardBuilder: _board)));
      await tester.pumpAndSettle();
      final finder = find.byWidgetPredicate((w) => w is PopupMenuButton);
      expect(finder, findsOneWidget);
      return tester.widget(finder);
    }

    List<Object?> values(WidgetTester tester, dynamic button) {
      final finder = find.byWidgetPredicate((w) => w is PopupMenuButton);
      final items = button.itemBuilder(tester.element(finder)) as List<dynamic>;
      return [
        for (final item in items)
          if (item is PopupMenuItem) item.value,
      ];
    }

    testWidgets('a finished game offers Play again, and it plays again',
        (tester) async {
      final source = await tester.runAsync(aFinishedGame);

      final button = await menuButton(tester);
      final entries = values(tester, button);
      expect(entries, contains('play_again'));
      expect(entries, isNot(contains('new_same')),
          reason: 'one action, named for a finished game');

      await tester.runAsync(() async {
        button.onSelected('play_again');
        for (var i = 0;
            i < 20 && find.byKey(_boardKey).evaluate().isEmpty;
            i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
      });
      await tester.pumpAndSettle();

      expect(find.byKey(_boardKey), findsOneWidget);
      await tester.runAsync(() async {
        final copy = await theNewGame(source!);
        expect(games.currentGame?.id, copy.id);
        await expectSameSetUp(source, copy);
        await expectUnchanged(source);
      });
    });

    testWidgets('a game still in play keeps "New with same players"',
        (tester) async {
      await tester.runAsync(() =>
          games.createGame('Partie', null, false, ['Alice', 'Bob'], null));

      final entries = values(tester, await menuButton(tester));
      expect(entries, contains('new_same'));
      expect(entries, isNot(contains('play_again')));
    });
  });

  test('the next name counts on from the last one', () {
    expect(nextGameName('Skyjo 3'), 'Skyjo 4');
    expect(nextGameName('Partie 9'), 'Partie 10');
    expect(nextGameName('Skyjo'), 'Skyjo 2');
    expect(nextGameName('Soirée'), 'Soirée 2');
    expect(nextGameName('99999999999999999999999'), '99999999999999999999999 2');
  });
}
