// The player statistics: the leaderboard filtered by game type, and the
// player card it opens on the same filter
// (wip/done/2026-09-19-player-statistics-screen-is-a-plain-list.md).
//
// The fixture is ten finished games between Alice, Bob and Carol: five of
// ZapZap (the lowest total wins) and five of Tarot (the highest wins), written
// through the repositories on a real in-memory database. Bob has a colour of
// his own; the others take the palette, as on the board.
//
//   ZapZap  A  B  C   places        Tarot  A  B  C   places
//   z1     10 20 30   1 2 3         t1    10 20 30   3 2 1
//   z2     30 10 20   3 1 2         t2    40 20 10   1 2 3
//   z3     15 25  5   2 3 1         t3    50 60  0   2 1 3
//   z4      5 30 20   1 3 2         t4    10 20 70   3 2 1
//   z5      8 12 40   1 2 3         t5     5  6  7   3 2 1

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
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/screens/player_card_screen.dart';
import 'package:countscore/screens/player_stats_screen.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/utils/player_colors.dart';
import 'package:countscore/widgets/player_avatars.dart';

const _zapzap = [
  [10, 20, 30],
  [30, 10, 20],
  [15, 25, 5],
  [5, 30, 20],
  [8, 12, 40],
];
const _tarot = [
  [10, 20, 30],
  [40, 20, 10],
  [50, 60, 0],
  [10, 20, 70],
  [5, 6, 7],
];
const _names = ['Alice', 'Bob', 'Carol'];
final int _bobColour = kPlayerPalette[3].toARGB32();

void main() {
  late AppDatabase db;
  late GameProvider games;
  late GameTypeProvider gameTypes;
  late int lastGameId;
  late Map<String, String> uuidOf;

  Future<void> seed() async {
    final types = await DriftGameTypeRepository(db).getAll();
    int typeId(String key) => types.firstWhere((t) => t.builtinKey == key).id!;
    final gameRepo = DriftGameRepository(db);
    final playerRepo = DriftPlayerRepository(db);
    final roundRepo = DriftRoundRepository(db);
    final scoreRepo = DriftScoreRepository(db);
    var minute = 0;

    Future<void> play(String key, bool lowestWins, List<int> totals) async {
      final gameId = await gameRepo.create(Game(
        name: '$key ${minute + 1}',
        gameTypeId: typeId(key),
        isLowestScoreWins: lowestWins,
        finishedAt: DateTime(2026, 9, 1, 20, minute++),
      ));
      final round = await roundRepo.create(Round(gameId: gameId, roundNumber: 1));
      for (var seat = 0; seat < 3; seat++) {
        final id = await playerRepo.create(Player(
          gameId: gameId,
          name: _names[seat],
          orderIndex: seat,
          colorValue: seat == 1 ? _bobColour : null,
        ));
        await scoreRepo.upsert(
            Score(playerId: id, roundId: round, value: totals[seat]));
      }
      lastGameId = gameId;
    }

    for (final t in _zapzap) {
      await play('zapzap', true, t);
    }
    for (final t in _tarot) {
      await play('tarot', false, t);
    }
    // Neither an unfinished game nor a finished one without a score counts.
    final open = await gameRepo.create(
        Game(name: 'open', gameTypeId: typeId('zapzap'), isLowestScoreWins: true));
    final r = await roundRepo.create(Round(gameId: open, roundNumber: 1));
    final a = await playerRepo
        .create(Player(gameId: open, name: 'Alice', orderIndex: 0));
    await scoreRepo.upsert(Score(playerId: a, roundId: r, value: 1));
    final empty = await gameRepo.create(Game(
        name: 'empty',
        gameTypeId: typeId('zapzap'),
        isLowestScoreWins: true,
        finishedAt: DateTime(2026, 9, 2)));
    await playerRepo.create(Player(gameId: empty, name: 'Bob', orderIndex: 0));

    final rows = await db
        .customSelect('SELECT name, uuid FROM players WHERE group_id IS NULL')
        .get();
    uuidOf = {
      for (final row in rows)
        row.data['name'] as String: row.data['uuid'] as String,
    };
  }

  setUp(() async {
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
    await seed();
  });

  tearDown(() => db.close());

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiProvider(
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
        home: PlayerStatsScreen(),
      ),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  String rankOf(WidgetTester tester, String name) =>
      textOf(tester, 'stats_rank_${uuidOf[name]}');

  String winsOf(WidgetTester tester, String name) =>
      textOf(tester, 'stats_wins_${uuidOf[name]}');

  Future<void> select(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key('stats_chip_$key')));
    await tester.pumpAndSettle();
  }

  testWidgets('no ExpansionTile; avatars in the colours of the board',
      (tester) async {
    await open(tester);
    expect(find.byType(ExpansionTile), findsNothing);

    final seated =
        await tester.runAsync(() => games.getPlayersOfGame(lastGameId));
    final board = playerColorsById(seated!);
    for (final p in seated) {
      final avatar = tester.widget<PlayerAvatar>(find.descendant(
        of: find.byKey(Key('stats_row_${uuidOf[p.name]}')),
        matching: find.byType(PlayerAvatar),
      ));
      expect(avatar.color, board[p.id], reason: p.name);
      expect(avatar.letters, 2);
    }
    // Two initials, and Bob's own colour.
    expect(find.text('Al'), findsWidgets);
    expect(board[seated[1].id], Color(_bobColour));
  });

  testWidgets('a game-type chip changes the ranks and the wins',
      (tester) async {
    await open(tester);
    // All games: Alice and Carol 4 of 10 each, Bob 2 of 10.
    expect(find.byKey(const Key('stats_chip_all')), findsOneWidget);
    expect(rankOf(tester, 'Alice'), '1');
    expect(rankOf(tester, 'Carol'), '1');
    expect(rankOf(tester, 'Bob'), '3');
    expect(winsOf(tester, 'Alice'), '4 · 40%');
    expect(winsOf(tester, 'Bob'), '2 · 20%');

    await select(tester, 'zapzap');
    expect(rankOf(tester, 'Alice'), '1');
    expect(winsOf(tester, 'Alice'), '3 · 60%');
    expect(rankOf(tester, 'Bob'), '2');
    expect(rankOf(tester, 'Carol'), '2');
    expect(winsOf(tester, 'Carol'), '1 · 20%');

    await select(tester, 'tarot');
    expect(rankOf(tester, 'Carol'), '1');
    expect(winsOf(tester, 'Carol'), '3 · 60%');
    expect(rankOf(tester, 'Alice'), '2');
    expect(winsOf(tester, 'Alice'), '1 · 20%');
    expect(find.byKey(const Key('stats_hero')), findsOneWidget);
  });

  testWidgets('lowest wins: the card of Alice on ZapZap', (tester) async {
    await open(tester);
    await select(tester, 'zapzap');
    await tester.tap(find.byKey(Key('stats_row_${uuidOf['Alice']}')));
    await tester.pumpAndSettle();

    expect(find.byType(PlayerCardScreen), findsOneWidget);
    expect(find.text('Alice · ZapZap'), findsOneWidget);
    expect(find.text('ZapZap · Lowest score wins'), findsOneWidget);
    Finder inTile(String key, String text) => find.descendant(
        of: find.byKey(Key(key)), matching: find.text(text));
    expect(inTile('card_games', '5'), findsOneWidget);
    expect(inTile('card_wins', '3'), findsOneWidget);
    expect(inTile('card_average_rank', '1.6'), findsOneWidget);
    expect(inTile('card_streak', 'Streak: 2 wins'), findsOneWidget);
    expect(inTile('card_record', 'Best: 5'), findsOneWidget);
    expect(textOf(tester, 'card_best_total'), '5');
    expect(textOf(tester, 'card_average_total'), '13.6');
    expect(inTile('card_most_beaten', 'Bob'), findsOneWidget);
    expect(find.byKey(const Key('card_rank_chart')), findsOneWidget);
  });

  testWidgets('highest wins: the card of Carol on Tarot, then Alice from the '
      'strip', (tester) async {
    await open(tester);
    await select(tester, 'tarot');
    await tester.tap(find.byKey(Key('stats_row_${uuidOf['Carol']}')));
    await tester.pumpAndSettle();

    expect(find.text('Carol · Tarot'), findsOneWidget);
    expect(find.text('Tarot · Highest score wins'), findsOneWidget);
    expect(textOf(tester, 'card_best_total'), '70');
    expect(find.text('1.8'), findsOneWidget);
    expect(find.text('Streak: 2 wins'), findsOneWidget);
    expect(find.text('Best: 70'), findsOneWidget);

    await tester.tap(find.byKey(Key('card_strip_${uuidOf['Alice']}')));
    await tester.pumpAndSettle();
    expect(find.text('Alice · Tarot'), findsOneWidget);
    expect(find.text('2.4'), findsOneWidget);
    expect(find.text('No winning streak'), findsOneWidget);
    expect(textOf(tester, 'card_best_total'), '50');
  });
}
