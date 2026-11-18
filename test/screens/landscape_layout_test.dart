// A phone turned sideways: 800 x 360 dp. The board, home and the statistics
// take their landscape layout there, and show at least twice the rows the
// portrait layout showed at that size
// (wip/done/2026-11-17-landscape-layout.md).
//
// "Today" is the count measured at 800 x 360 on the portrait layout, before
// the landscape one existed (main at 9190a50), with these very fixtures: the
// board showed 1 round in full with 4 players and none with 8, home no game
// card in full, the statistics no leaderboard row in full. Twice nothing is
// nothing, so each test also asks for a floor of its own.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/models/round.dart';
import 'package:countscore/models/score.dart';
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/providers/game_type_provider.dart';
import 'package:countscore/providers/settings_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/screens/home_screen.dart';
import 'package:countscore/screens/player_stats_screen.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/utils/app_theme.dart';

import '../support/board_harness.dart';

const _landscape = Size(800, 360);

/// The rows the portrait layout showed in full at 800 x 360 (see the header).
const _todayBoardRounds = {4: 1, 8: 0};
const _todayHomeCards = 0;
const _todayStatsRows = 0;

/// At least twice [today], and never fewer than [floor].
Matcher _atLeastTwice(int today, int floor) =>
    greaterThanOrEqualTo(2 * today > floor ? 2 * today : floor);

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// How many of [rows] lie wholly inside [viewport].
int _fullyInside(WidgetTester tester, Finder rows, Rect viewport) {
  var n = 0;
  for (final element in rows.evaluate()) {
    final box = element.renderObject! as RenderBox;
    if (!box.attached || !box.hasSize) continue;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect.top >= viewport.top - 0.5 &&
        rect.bottom <= viewport.bottom + 0.5 &&
        rect.left >= viewport.left - 0.5 &&
        rect.right <= viewport.right + 0.5) {
      n++;
    }
  }
  return n;
}

Widget _app(Widget home, List<ChangeNotifierProvider> providers) =>
    MultiProvider(
      providers: providers,
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
        home: home,
      ),
    );

GameProvider _gameProvider(AppDatabase db) => GameProvider(
  gameRepo: DriftGameRepository(db),
  playerRepo: DriftPlayerRepository(db),
  roundRepo: DriftRoundRepository(db),
  scoreRepo: DriftScoreRepository(db),
  gameTypeRepo: DriftGameTypeRepository(db),
  statsRepo: DriftPlayerStatsRepository(db),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the board at 800 x 360', () {
    late BoardHarness board;
    setUp(() => board = BoardHarness());
    tearDown(() => board.close());

    Future<void> openBoard(WidgetTester tester, List<String> names) async {
      await tester.runAsync(
        () => board.aGame(
          names,
          rounds: [
            for (var r = 0; r < 12; r++)
              [for (var p = 0; p < names.length; p++) (r * 7 + p * 3) % 40],
          ],
        ),
      );
      _setSize(tester, _landscape);
      await tester.pumpWidget(board.wrap());
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
    }

    int visibleRounds(WidgetTester tester) {
      final first = board.games.currentPlayers.first;
      return _fullyInside(
        tester,
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith(
                'board_cell_${first.id}_',
              ),
        ),
        tester.getRect(find.byKey(const Key('board_score_grid'))),
      );
    }

    for (final names in [
      ['Alice', 'Bob', 'Carol', 'Dave'],
      ['Ann', 'Ben', 'Cat', 'Dan', 'Eve', 'Fay', 'Gus', 'Hal'],
    ]) {
      testWidgets(
        '${names.length} players: at least twice the rounds, no overflow',
        (tester) async {
          await openBoard(tester, names);
          expect(tester.takeException(), isNull);
          expect(
            visibleRounds(tester),
            _atLeastTwice(_todayBoardRounds[names.length]!, 5),
          );
          // Every lane header still names its player and shows a total.
          for (final p in board.games.currentPlayers) {
            final header = find.byKey(Key('board_lane_header_${p.id}'));
            expect(header, findsOneWidget);
            expect(tester.getSize(header).height, 64);
            expect(
              find.descendant(
                of: header,
                matching: find.text('${board.games.getPlayerTotal(p.id!)}'),
              ),
              findsOneWidget,
            );
            if (names.length == 4) {
              expect(
                find.descendant(of: header, matching: find.text(p.name)),
                findsOneWidget,
              );
            }
          }
          expect(find.byKey(const Key('board_leader_crown')), findsOneWidget);
          // The round button sits in a rail beside the grid, not under it.
          final button = tester.getRect(
            find.byKey(const Key('board_add_round')),
          );
          final grid = tester.getRect(
            find.byKey(const Key('board_score_grid')),
          );
          expect(button.left, greaterThanOrEqualTo(grid.right));
          expect(grid.bottom, _landscape.height);
        },
      );
    }

    testWidgets('in portrait, at 360 x 800, the board is the one it was', (
      tester,
    ) async {
      await tester.runAsync(
        () => board.aGame(
          ['Alice', 'Bob'],
          rounds: [
            [1, 2],
          ],
        ),
      );
      _setSize(tester, const Size(360, 800));
      await tester.pumpWidget(board.wrap());
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      final p = board.games.currentPlayers.first;
      expect(
        tester.getSize(find.byKey(Key('board_lane_header_${p.id}'))).height,
        156,
      );
      // The round button spans the width, under the grid.
      final button = tester.getRect(find.byKey(const Key('board_add_round')));
      final grid = tester.getRect(find.byKey(const Key('board_score_grid')));
      expect(button.top, greaterThanOrEqualTo(grid.bottom));
      expect(button.width, 360 - 32);
      expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);
    });

    testWidgets('a landscape window 500 dp high keeps the portrait board', (
      tester,
    ) async {
      await tester.runAsync(
        () => board.aGame(
          ['Alice', 'Bob'],
          rounds: [
            [1, 2],
          ],
        ),
      );
      _setSize(tester, const Size(1000, 500));
      await tester.pumpWidget(board.wrap());
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      final p = board.games.currentPlayers.first;
      expect(
        tester.getSize(find.byKey(Key('board_lane_header_${p.id}'))).height,
        156,
      );
      expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);
    });

    testWidgets('a round is entered through the keypad, no overflow', (
      tester,
    ) async {
      await openBoard(tester, ['Alice', 'Bob', 'Carol', 'Dave']);
      await tester.tap(find.byKey(const Key('board_add_round')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // The whole sheet is on screen: chips and number beside the pad.
      for (final key in [
        'keypad_value',
        'keypad_total_after',
        'keypad_digit_1',
        'keypad_digit_0',
        'keypad_primary',
      ]) {
        final rect = tester.getRect(find.byKey(Key(key)));
        expect(rect.top, greaterThanOrEqualTo(0), reason: key);
        expect(rect.bottom, lessThanOrEqualTo(_landscape.height), reason: key);
      }
      expect(
        tester.getRect(find.byKey(const Key('keypad_value'))).right,
        lessThan(tester.getRect(find.byKey(const Key('keypad_digit_1'))).left),
      );
      for (final score in [1, 2, 3, 4]) {
        await tester.tap(find.byKey(Key('keypad_digit_$score')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('keypad_primary')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(board.games.currentRounds, hasLength(13));
    });
  });

  group('home at 800 x 360', () {
    late AppDatabase db;
    late GameProvider games;
    late GameTypeProvider gameTypes;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      games = _gameProvider(db);
      gameTypes = GameTypeProvider(repo: DriftGameTypeRepository(db));
    });
    tearDown(() => db.close());

    Future<void> seed() async {
      for (var i = 1; i <= 9; i++) {
        final id = await games.createGame('Game $i', null, false, [
          'Alice',
          'Bob',
          'Dave',
        ], null);
        await games.loadGame(id);
        await games.addRound();
        final round = games.currentRounds.last;
        for (final p in games.currentPlayers) {
          await games.updateScore(p.id!, round.id!, p.name.length * i);
        }
        if (i < 9) await games.setGameFinished(id, true);
      }
      await games.loadGames();
    }

    Future<void> openHome(WidgetTester tester, Size size) async {
      await tester.runAsync(seed);
      _setSize(tester, size);
      await tester.pumpWidget(
        _app(const HomeScreen(), [
          ChangeNotifierProvider<GameProvider>.value(value: games),
          ChangeNotifierProvider<GameTypeProvider>.value(value: gameTypes),
        ]),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('at least twice the game cards, no overflow', (tester) async {
      await openHome(tester, _landscape);

      expect(tester.takeException(), isNull);
      // The Resume card is a strip: name, players, leader and button on one
      // line.
      final hero = find.byKey(const Key('resumeHero'));
      expect(hero, findsOneWidget);
      expect(tester.getSize(hero).height, lessThanOrEqualTo(80));
      expect(
        find.descendant(of: hero, matching: find.text('Game 9')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('resumeHeroLeader')), findsOneWidget);
      final list = tester.getRect(find.byType(Scrollable).first);
      final cards = _fullyInside(tester, find.byType(Card), list);
      expect(cards, _atLeastTwice(_todayHomeCards, 2));
    });

    testWidgets('in portrait, at 360 x 800, the Resume card is the hero', (
      tester,
    ) async {
      await openHome(tester, const Size(360, 800));
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const Key('resumeHero'))).height,
        greaterThan(120),
      );
      expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);
    });
  });

  group('the statistics at 800 x 360', () {
    late AppDatabase db;
    late GameProvider games;
    late GameTypeProvider gameTypes;
    const names = [
      'Alice', 'Bob', 'Carol', 'Dave', 'Eve', 'Fay', 'Gus', 'Hal', //
    ];

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      games = _gameProvider(db);
      gameTypes = GameTypeProvider(repo: DriftGameTypeRepository(db));
    });
    tearDown(() => db.close());

    Future<void> seed() async {
      final types = await DriftGameTypeRepository(db).getAll();
      final zapzap = types.firstWhere((t) => t.builtinKey == 'zapzap').id!;
      for (var g = 0; g < 6; g++) {
        final gameId = await DriftGameRepository(db).create(
          Game(
            name: 'zapzap $g',
            gameTypeId: zapzap,
            isLowestScoreWins: true,
            finishedAt: DateTime(2026, 9, 1, 20, g),
          ),
        );
        final round = await DriftRoundRepository(db)
            .create(Round(gameId: gameId, roundNumber: 1));
        for (var seat = 0; seat < names.length; seat++) {
          final id = await DriftPlayerRepository(
            db,
          ).create(Player(gameId: gameId, name: names[seat], orderIndex: seat));
          await DriftScoreRepository(db).upsert(
            Score(playerId: id, roundId: round, value: (seat * 5 + g * 3) % 23),
          );
        }
      }
    }

    testWidgets('at least twice the leaderboard rows, no overflow', (
      tester,
    ) async {
      await tester.runAsync(seed);
      _setSize(tester, _landscape);
      await tester.pumpWidget(
        _app(const PlayerStatsScreen(), [
          ChangeNotifierProvider<GameProvider>.value(value: games),
          ChangeNotifierProvider<GameTypeProvider>.value(value: gameTypes),
        ]),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('stats_hero')), findsOneWidget);
      final rows = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('stats_row_'),
      );
      final list = tester.getRect(find.byKey(const Key('stats_leaderboard')));
      expect(
        _fullyInside(tester, rows, list),
        _atLeastTwice(_todayStatsRows, 3),
      );
      // The best win rate sits beside the leaderboard, not above it.
      expect(
        tester.getRect(find.byKey(const Key('stats_hero'))).right,
        lessThanOrEqualTo(list.left),
      );

      // The player card a row opens: summary and totals side by side.
      await tester.tap(rows.first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final summary = tester.getRect(
        find.byKey(const Key('card_landscape_summary')),
      );
      final details = tester.getRect(
        find.byKey(const Key('card_landscape_details')),
      );
      expect(summary.right, lessThanOrEqualTo(details.left));
      expect(find.byKey(const Key('card_games')), findsOneWidget);
      expect(find.byKey(const Key('card_average_total')), findsOneWidget);
    });

    testWidgets('in portrait, at 360 x 800, the leaderboard is one list', (
      tester,
    ) async {
      await tester.runAsync(seed);
      _setSize(tester, const Size(360, 800));
      await tester.pumpWidget(
        _app(const PlayerStatsScreen(), [
          ChangeNotifierProvider<GameProvider>.value(value: games),
          ChangeNotifierProvider<GameTypeProvider>.value(value: gameTypes),
        ]),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('stats_leaderboard')), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('stats_hero'))).width,
        360 - 32,
      );
      expect(tester.getSize(find.byType(AppBar)).height, kToolbarHeight);
    });
  });
  // The one-row-per-player board on a phone on its side: the seat / ranking
  // switch sits in the app bar beside the game's name, and the round columns
  // are packed, so more than the portrait layout's four rounds show.
  group('the rows board at 800 x 360', () {
    late BoardHarness board;
    setUp(() => board = BoardHarness());
    tearDown(() => board.close());

    Future<void> openRows(WidgetTester tester, Size size) async {
      final settings = SettingsProvider();
      await tester.runAsync(() => settings.ready);
      await tester.runAsync(() => settings.setBoardView(BoardView.rows));
      await tester.runAsync(
        () => board.aGame(
          ['Zoe', 'Adam', 'Mia'],
          rounds: [
            for (var r = 0; r < 12; r++) [30 - r, r + 1, (r * 5) % 17],
          ],
        ),
      );
      _setSize(tester, size);
      await tester.pumpWidget(board.wrap(settings: settings));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
    }

    testWidgets('the order switch is in the app bar, beside the name', (
      tester,
    ) async {
      await openRows(tester, _landscape);

      expect(tester.takeException(), isNull);
      final selector = tester.getRect(
        find.byKey(const Key('board_rows_order')),
      );
      final bar = tester.getRect(find.byType(AppBar));
      final title = tester.getRect(find.text('Partie'));
      expect(selector.bottom, lessThanOrEqualTo(bar.bottom));
      expect(selector.left, greaterThan(title.right));

      double rowY(String name) => tester
          .getTopLeft(
            find.byKey(Key('board_row_${board.playerNamed(name).id}')),
          )
          .dy;
      expect(rowY('Zoe'), lessThan(rowY('Adam')));
      await tester.tap(find.text('Ranking'));
      await tester.pumpAndSettle();
      expect(
        rowY('Zoe'),
        greaterThan(rowY('Adam')),
        reason: 'Zoe totals the most, so she ranks last',
      );
    });

    testWidgets('more than four rounds are in view, none cut off', (
      tester,
    ) async {
      await openRows(tester, _landscape);

      final first = board.games.currentPlayers.first;
      final viewport = tester.getRect(
        find.byKey(const Key('board_rows_rounds')),
      );
      var inside = 0;
      for (final e in find.byWidgetPredicate((w) {
        final k = w.key;
        return k is ValueKey<String> &&
            k.value.startsWith('board_rows_cell_${first.id}_');
      }).evaluate()) {
        final box = e.renderObject! as RenderBox;
        final r = box.localToGlobal(Offset.zero) & box.size;
        if (r.left >= viewport.left - 0.5 && r.right <= viewport.right + 0.5) {
          inside++;
        }
      }
      expect(inside, greaterThanOrEqualTo(7));
    });

    testWidgets('in portrait the switch stays above the rows, four rounds', (
      tester,
    ) async {
      await openRows(tester, const Size(400, 800));

      final selector = tester.getRect(
        find.byKey(const Key('board_rows_order')),
      );
      expect(selector.top, greaterThanOrEqualTo(kToolbarHeight));
      final viewport = tester.getRect(
        find.byKey(const Key('board_rows_rounds')),
      );
      final first = board.games.currentPlayers.first;
      final cell = tester.getRect(
        find.byKey(
          Key(
            'board_rows_cell_${first.id}_${board.games.currentRounds.last.id}',
          ),
        ),
      );
      expect(cell.width, moreOrLessEquals(viewport.width / 4, epsilon: 0.5));
    });
  });
}
