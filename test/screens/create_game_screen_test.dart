// The New game screen, redrawn in direction A
// (wip/done/2026-09-19-new-game-screen-is-a-bare-form.md): game-type tiles,
// most recent first; the name as a light title; the players in seat order,
// reorderable, in their display colours; "who's playing" as a sheet; "Start".

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
import 'package:countscore/screens/create_game_screen.dart';
import 'package:countscore/screens/game_board_screen.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/utils/app_theme.dart';
import 'package:countscore/utils/player_colors.dart';
import 'package:countscore/widgets/player_avatars.dart';

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

const _boardKey = Key('test_board');

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

  /// The screen, [realBoard] opening the real board after "Start" rather than
  /// a stand-in.
  Widget wrap({bool realBoard = false, Locale locale = const Locale('en')}) {
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
        theme: buildAppTheme(Brightness.light),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('ja')],
        locale: locale,
        home: CreateGameScreen(
          boardBuilder: realBoard
              ? (_) => GameBoardScreen(analysisRepo: _NoAnalysis())
              : (_) => const Scaffold(key: _boardKey, body: Text('board')),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester,
      {bool realBoard = false, Locale locale = const Locale('en')}) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(realBoard: realBoard, locale: locale));
    await tester.pumpAndSettle();
  }

  Future<int> typeId(String builtinKey) async {
    await gameTypes.loadGameTypes();
    return gameTypes.gameTypes.firstWhere((t) => t.builtinKey == builtinKey).id!;
  }

  /// A game "Partie 7" of Skyjo, seated Vincent, Thibaut, Laurent, Lionel.
  Future<void> aPreviousGame() async {
    await games.createGame('Partie 7', await typeId('skyjo'), true,
        ['Vincent', 'Thibaut', 'Laurent', 'Lionel'], null);
  }

  Future<void> sameAsLastGame(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('create_add_player')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('player_picker_same_as')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('player_picker_confirm')));
    await tester.pumpAndSettle();
  }

  List<String> seatNames(WidgetTester tester) {
    final rows = find.descendant(
        of: find.byKey(const Key('seat_order_list')),
        matching: find.byType(PlayerAvatar));
    return [
      for (final e in rows.evaluate()) (e.widget as PlayerAvatar).name,
    ];
  }

  Color avatarColourIn(Finder scope, String name) {
    final avatar = find.descendant(
        of: scope,
        matching: find.byWidgetPredicate(
            (w) => w is PlayerAvatar && w.name == name));
    expect(avatar, findsWidgets);
    return {for (final e in avatar.evaluate()) (e.widget as PlayerAvatar).color}
        .single;
  }

  // wip/done/2026-09-19-pwa-reload-reruns-the-database-creation.md: a PWA
  // whose seeding failed had no types, and the screen said "Loading…" forever.
  testWidgets('with no game types: an empty state, not an endless loading line',
      (tester) async {
    await db.customStatement('DELETE FROM game_types');

    await open(tester);

    expect(tester.takeException(), isNull);
    final empty = find.byKey(const Key('game_type_empty'));
    expect(empty, findsOneWidget);
    expect((tester.widget<Text>(empty)).data, 'No game types');
    expect(find.text('Loading game types...'), findsNothing);
    expect(find.byKey(const Key('game_type_all')), findsNothing);
  });

  testWidgets('at 412 dp: tiles, rule line, seats and Start, in that order',
      (tester) async {
    await aPreviousGame();
    await open(tester, locale: const Locale('fr'));
    await sameAsLastGame(tester);

    expect(tester.takeException(), isNull);
    // The name as a title, prefilled after the last game's.
    expect(find.text('Partie 8'), findsOneWidget);

    // Six tiles, three a row, the last game's type first and selected.
    final tiles = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key as ValueKey<String>).value.startsWith('game_type_tile_'));
    expect(tiles, findsNWidgets(6));
    final rects = [for (final e in tiles.evaluate()) tester.getRect(find.byWidget(e.widget))];
    expect(rects[0].top, rects[2].top);
    expect(rects[3].top, greaterThan(rects[0].bottom));
    for (final r in rects) {
      expect(r.left, greaterThanOrEqualTo(0));
      expect(r.right, lessThanOrEqualTo(412));
    }
    final skyjo = await typeId('skyjo');
    expect(tester.getRect(find.byKey(Key('game_type_tile_$skyjo'))), rects[0]);
    expect(find.textContaining('Tous les jeux ('), findsOneWidget);
    expect(find.byKey(const Key('create_rule_line')), findsOneWidget);

    // Seats in the last game's order, the first one dealing.
    expect(seatNames(tester), ['Vincent', 'Thibaut', 'Laurent', 'Lionel']);
    expect(find.text('donne'), findsOneWidget);
    expect(find.text('JOUEURS · ORDRE DE JEU'), findsOneWidget);
    final ruleBottom =
        tester.getRect(find.byKey(const Key('create_rule_line'))).bottom;
    expect(tester.getRect(find.byKey(const Key('seat_row_0'))).top,
        greaterThan(ruleBottom));

    // A full-width primary button at the bottom.
    final start = tester.getRect(find.byKey(const Key('create_game_submit')));
    expect(find.text('Commencer · 4 joueurs'), findsOneWidget);
    expect(start.width, greaterThan(412 - 2 * 24));
    expect(start.bottom, greaterThan(915 - 100));
  });

  testWidgets('a player has the same colour here and on the board',
      (tester) async {
    // Two players who both own the palette's first colour: the later seat
    // loses it, here as on the board.
    final red = kPlayerPalette.first.toARGB32();
    await games.createGame('Partie 7', await typeId('skyjo'), true,
        ['Ann', 'Bob', 'Cid'], {'Ann': red, 'Bob': red});
    await open(tester, realBoard: true);
    await sameAsLastGame(tester);

    final list = find.byKey(const Key('seat_order_list'));
    final here = {
      for (final n in ['Ann', 'Bob', 'Cid']) n: avatarColourIn(list, n),
    };
    expect(here['Ann'], isNot(here['Bob']));

    await tester.tap(find.byKey(const Key('create_game_submit')));
    await tester.pumpAndSettle();

    expect(find.byType(GameBoardScreen), findsOneWidget);
    final board = find.byType(GameBoardScreen);
    for (final n in ['Ann', 'Bob', 'Cid']) {
      expect(avatarColourIn(board, n), here[n], reason: n);
    }
  });

  testWidgets('reordering two players changes the seat order of the game',
      (tester) async {
    await aPreviousGame();
    await open(tester);
    await sameAsLastGame(tester);
    expect(seatNames(tester), ['Vincent', 'Thibaut', 'Laurent', 'Lionel']);

    // Vincent's handle, dragged down just under one row (a row is 66 dp with
    // its gap): past Thibaut's middle, short of Laurent's.
    final handle = find.byKey(const Key('seat_handle_0'));
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(seatNames(tester), ['Thibaut', 'Vincent', 'Laurent', 'Lionel']);

    await tester.tap(find.byKey(const Key('create_game_submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(_boardKey), findsOneWidget);

    final created = games.currentGame!;
    expect(created.name, 'Partie 8');
    final seated = await games.getPlayersOfGame(created.id!);
    expect(seated.map((p) => p.name),
        ['Thibaut', 'Vincent', 'Laurent', 'Lionel']);
    expect(seated.map((p) => p.orderIndex), [0, 1, 2, 3]);
  });

  testWidgets('the sheet creates a new player and seats him after the others',
      (tester) async {
    await aPreviousGame();
    await open(tester);

    await tester.tap(find.byKey(const Key('create_add_player')));
    await tester.pumpAndSettle();
    // Known players as chips; checking two of them.
    await tester.tap(find.byKey(const Key('player_chip_Lionel')));
    await tester.tap(find.byKey(const Key('player_chip_Vincent')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('player_picker_search')), 'Sophie');
    await tester.pump();
    expect(find.text('Create “Sophie”'), findsOneWidget);
    await tester.tap(find.byKey(const Key('player_picker_create')));
    await tester.pump();
    expect(find.text('Add 3 players'), findsOneWidget);
    await tester.tap(find.byKey(const Key('player_picker_confirm')));
    await tester.pumpAndSettle();

    expect(seatNames(tester), ['Lionel', 'Vincent', 'Sophie']);
    expect(find.text('Start · 3 players'), findsOneWidget);
  });

  testWidgets('"All games" picks a type that is not on the tiles',
      (tester) async {
    await open(tester);
    final tiles = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key as ValueKey<String>).value.startsWith('game_type_tile_'));
    final onTiles = {
      for (final e in tiles.evaluate()) (e.widget.key as ValueKey<String>).value,
    };
    final other = gameTypes.gameTypes
        .firstWhere((t) => !onTiles.contains('game_type_tile_${t.id}'));

    await tester.tap(find.byKey(const Key('game_type_all')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(Key('all_game_types_${other.id}')), 200,
        scrollable: find.descendant(
            of: find.byKey(const Key('all_game_types_list')),
            matching: find.byType(Scrollable)));
    await tester.tap(find.byKey(Key('all_game_types_${other.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('game_type_tile_${other.id}')), findsOneWidget);
    expect(tiles, findsNWidgets(6));
  });

  testWidgets('the first game is named in the app language', (tester) async {
    await open(tester);
    expect(find.text('Game 1'), findsOneWidget);
    expect(find.text('Partie 1'), findsNothing);
  });

  testWidgets('the first game is named in French in French', (tester) async {
    await open(tester, locale: const Locale('fr'));
    expect(find.text('Partie 1'), findsOneWidget);
  });

  testWidgets('the first game is named in Japanese in Japanese',
      (tester) async {
    await open(tester, locale: const Locale('ja'));
    expect(find.text('ゲーム1'), findsOneWidget);
  });

  testWidgets('"Other" offers the choice of win rule', (tester) async {
    await games.createGame('Soirée', await typeId('other'), true,
        ['Ann', 'Bob'], null);
    await open(tester);
    expect(find.byKey(const Key('create_win_rule')), findsOneWidget);
    expect(find.byKey(const Key('create_rule_line')), findsNothing);
    expect(find.text('Soirée 2'), findsOneWidget);
  });
}
