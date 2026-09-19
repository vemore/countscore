// The Players screen counts what the leaderboard counts — finished games with
// a score — and draws each player as the leaderboard does: two letters, in
// the leaderboard's colour
// (wip/done/2026-09-19-players-screen-counts-open-games-and-shows-blue-avatars.md).

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/models/player_stats.dart';
import 'package:countscore/models/round.dart';
import 'package:countscore/models/score.dart';
import 'package:countscore/providers/game_provider.dart';
import 'package:countscore/repositories/drift/drift_repositories.dart';
import 'package:countscore/screens/players_screen.dart';
import 'package:countscore/services/drift/database.dart';
import 'package:countscore/widgets/player_avatars.dart';

void main() {
  late AppDatabase db;
  late GameProvider games;
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  /// A game of [names] with one round of [scores], finished or not.
  Future<void> play(List<String> names, List<int> scores,
      {required bool finished, int? bobColour}) async {
    final gameId = await DriftGameRepository(db).create(Game(
      name: 'G',
      isLowestScoreWins: false,
      finishedAt: finished ? DateTime(2026, 9, 1) : null,
    ));
    final round = await DriftRoundRepository(db)
        .create(Round(gameId: gameId, roundNumber: 1));
    for (var i = 0; i < names.length; i++) {
      final id = await DriftPlayerRepository(db).create(Player(
        gameId: gameId,
        name: names[i],
        orderIndex: i,
        colorValue: names[i] == 'Bob' ? bobColour : null,
      ));
      await DriftScoreRepository(db)
          .upsert(Score(playerId: id, roundId: round, value: scores[i]));
    }
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
    // Alice wins the finished game; the open one, where she leads too, does
    // not count. Bob keeps a Material colour of his own.
    await play(['Alice', 'Bob'], [20, 10],
        finished: true, bobColour: Colors.green.toARGB32());
    await play(['Alice', 'Bob'], [30, 5], finished: false);
    // Chloé has played an open game only.
    await play(['Chloé', 'Bob'], [1, 2], finished: false);
  });

  tearDown(() => db.close());

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ChangeNotifierProvider<GameProvider>.value(
      value: games,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en', '')],
        locale: Locale('en', ''),
        home: PlayersScreen(),
      ),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
  }

  String countsOf(WidgetTester tester, String name) =>
      tester.widget<Text>(find.byKey(Key('players_counts_$name'))).data!;

  PlayerAvatar avatarOf(WidgetTester tester, String name) =>
      tester.widget<PlayerAvatar>(find.byKey(Key('players_avatar_$name')));

  testWidgets('finished games only, as on the leaderboard', (tester) async {
    await open(tester);

    expect(countsOf(tester, 'Alice'),
        '${l10n.gamesCount(1)}\n${l10n.winsCount(1)}');
    expect(countsOf(tester, 'Bob'),
        '${l10n.gamesCount(1)}\n${l10n.winsCount(0)}');
    expect(countsOf(tester, 'Chloé'),
        '${l10n.gamesCount(0)}\n${l10n.winsCount(0)}');

    final results =
        (await tester.runAsync(() => games.getFinishedGameResults()))!;
    final board = {
      for (final e in buildLeaderboard(results, kAllGameTypes)) e.name: e,
    };
    expect(board['Alice']!.games, 1);
    expect(board['Alice']!.wins, 1);
  });

  testWidgets('two-letter avatars in the leaderboard colours; no blue default',
      (tester) async {
    await open(tester);

    final results =
        (await tester.runAsync(() => games.getFinishedGameResults()))!;
    final colours = playerColorsByUuid(results);
    final uuidOf = {
      for (final p in results.single.participants) p.name: p.playerUuid,
    };
    for (final name in ['Alice', 'Bob']) {
      final avatar = avatarOf(tester, name);
      expect(avatar.color, colours[uuidOf[name]], reason: name);
      expect(avatar.letters, 2);
    }
    expect(find.text('Al'), findsOneWidget);
    expect(avatarOf(tester, 'Bob').color.toARGB32(),
        Colors.green.toARGB32());
    // Chloé, in no finished game, takes a colour nobody else shows.
    final chloe = avatarOf(tester, 'Chloé').color;
    expect(chloe, isNot(colours[uuidOf['Alice']]));
    expect(chloe, isNot(colours[uuidOf['Bob']]));
    expect(chloe, isNot(Colors.blue));
  });

  testWidgets('the delete confirmation counts every game, open ones too',
      (tester) async {
    await open(tester);

    await tester.tap(find.descendant(
      of: find.byKey(const Key('players_row_Bob')),
      matching: find.byIcon(Icons.delete),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();

    expect(find.text(l10n.confirmDeletePlayer('Bob', 3)), findsOneWidget);
  });
}
