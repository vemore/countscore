// Scores are entered through a keypad bottom sheet: "Round N" walks the
// players in seat order and writes the round in one go on "Validate round";
// a tapped cell opens the same sheet on that one score, with "Save"
// (wip/done/2026-09-18-score-entry-takes-a-dialog-per-cell.md).

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game_analysis.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/models/player.dart';
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

  /// A type keyed [builtinKey], optionally eliminating a player over 100.
  Future<int> aType(String builtinKey, {bool eliminates = false}) async {
    final existing = gameTypes.gameTypes
        .where((t) => t.builtinKey == builtinKey)
        .firstOrNull;
    if (existing != null && !eliminates) return existing.id!;
    return gameTypes.createGameType(GameType(
      name: builtinKey,
      builtinKey: existing == null ? builtinKey : null,
      iconCodePoint: Icons.casino.codePoint,
      cardColorValue: Colors.blue.toARGB32(),
      isLowestScoreWins: true,
      playerDeadConditionType:
          eliminates ? PlayerDeadConditionType.over : null,
      playerDeadThreshold: eliminates ? 100 : null,
    ));
  }

  /// Opens the board on a game of [typeId] with [names], and [rounds] rounds
  /// already scored (each row one score per player, in seat order).
  Future<void> openBoard(
    WidgetTester tester,
    List<String> names, {
    int? typeId,
    List<List<int>> rounds = const [],
  }) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final id = await games.createGame('Partie', typeId, true, names, null);
    await games.loadGame(id);
    for (final row in rounds) {
      await games.addRoundWithScores({
        for (var i = 0; i < row.length; i++)
          games.currentPlayers[i].id!: row[i],
      });
    }
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
  }

  Player playerNamed(String name) =>
      games.currentPlayers.firstWhere((p) => p.name == name);

  final sheet = find.byKey(const Key('keypad_sheet'));
  final primary = find.byKey(const Key('keypad_primary'));

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  /// Types [score] on the keypad, digit by digit, "−" first for a negative.
  Future<void> type(WidgetTester tester, int score) async {
    if (score < 0) await tapKey(tester, 'keypad_sign');
    for (final d in '${score.abs()}'.split('')) {
      await tapKey(tester, 'keypad_digit_$d');
    }
  }

  Future<void> openRound(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('board_add_round')));
    await tester.pumpAndSettle();
    expect(sheet, findsOneWidget);
  }

  testWidgets(
      'a full 4-player round goes through the keypad and is written only '
      'on "Validate round"', (tester) async {
    await openBoard(tester, ['Lionel', 'Laurent', 'Thibaut', 'Vincent']);
    expect(find.text(l10n.boardRoundButton(1)), findsOneWidget);

    await openRound(tester);
    const scores = [4, 11, -3, 12];
    for (var i = 0; i < scores.length; i++) {
      expect(find.byType(TextField), findsNothing);
      await type(tester, scores[i]);
      if (i < scores.length - 1) {
        expect(
            find.text(l10n.keypadNext(games.currentPlayers[i + 1].name)),
            findsOneWidget);
        expect(games.currentRounds, isEmpty,
            reason: 'no row exists before the round is validated');
      } else {
        expect(find.text(l10n.keypadValidateRound), findsOneWidget);
      }
      await tester.tap(primary);
      await tester.pumpAndSettle();
    }

    expect(sheet, findsNothing);
    expect(games.currentRounds, hasLength(1));
    final round = games.currentRounds.single;
    for (var i = 0; i < scores.length; i++) {
      expect(games.getScore(games.currentPlayers[i].id!, round.id!), scores[i]);
    }
    expect(find.text(l10n.boardRoundButton(2)), findsOneWidget);
  });

  testWidgets('the keypad shows the total after the typed score',
      (tester) async {
    await openBoard(tester, ['Ann', 'Bob'], rounds: [
      [50, 20],
    ]);
    await openRound(tester);
    await type(tester, 12);
    expect(find.text(l10n.keypadTotalAfter(62)), findsOneWidget);
    await tapKey(tester, 'keypad_backspace');
    expect(find.text(l10n.keypadTotalAfter(51)), findsOneWidget);
    await tapKey(tester, 'keypad_sign');
    expect(find.text(l10n.keypadTotalAfter(49)), findsOneWidget);
  });

  testWidgets('closing the sheet halfway leaves the round count unchanged',
      (tester) async {
    await openBoard(tester, ['Ann', 'Bob', 'Cid'], rounds: [
      [1, 2, 3],
    ]);
    await openRound(tester);
    await type(tester, 7);
    await tester.tap(primary);
    await tester.pumpAndSettle();
    await type(tester, 9);

    // Tapping the barrier dismisses the sheet.
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();

    expect(sheet, findsNothing);
    expect(games.currentRounds, hasLength(1));
    expect(await DriftRoundRepository(db).getByGame(games.currentGame!.id!),
        hasLength(1));
  });

  testWidgets('editing a past cell updates that score and its total',
      (tester) async {
    await openBoard(tester, ['Ann', 'Bob'], rounds: [
      [10, 20],
      [5, 6],
    ]);
    final ann = playerNamed('Ann');
    final first = games.currentRounds.first;

    await tester.tap(find.byKey(Key('board_cell_${ann.id}_${first.id}')));
    await tester.pumpAndSettle();
    expect(sheet, findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text(l10n.save), findsOneWidget);
    expect(find.text(l10n.keypadTotalAfter(15)), findsOneWidget,
        reason: 'the score being edited is already counted once');

    // The first digit replaces the value that was there.
    await type(tester, 30);
    expect(find.text(l10n.keypadTotalAfter(35)), findsOneWidget);
    await tester.tap(primary);
    await tester.pumpAndSettle();

    expect(sheet, findsNothing);
    expect(games.getScore(ann.id!, first.id!), 30);
    expect(games.getPlayerTotal(ann.id!), 35);
    expect(games.currentRounds, hasLength(2));
    expect(
        find.descendant(
            of: find.byKey(Key('board_lane_header_${ann.id}')),
            matching: find.text('35')),
        findsOneWidget);
  });

  testWidgets('closing the sheet on a cell leaves the score as it was',
      (tester) async {
    await openBoard(tester, ['Ann', 'Bob'], rounds: [
      [10, 20],
    ]);
    final ann = playerNamed('Ann');
    final first = games.currentRounds.first;
    await tester.tap(find.byKey(Key('board_cell_${ann.id}_${first.id}')));
    await tester.pumpAndSettle();
    await type(tester, 99);
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();
    expect(games.getScore(ann.id!, first.id!), 10);
  });

  group('the bottom-left key', () {
    testWidgets('reads "0 ZapZap" for ZapZap, and enters a zero',
        (tester) async {
      await gameTypes.loadGameTypes();
      final zapzap = await aType('zapzap');
      await openBoard(tester, ['Ann', 'Bob'], typeId: zapzap);
      await openRound(tester);

      expect(find.text(l10n.keypadZeroZapZap), findsOneWidget);
      await tapKey(tester, 'keypad_zapzap');
      // A zero for Ann, and on to Bob.
      expect(find.text(l10n.keypadValidateRound), findsOneWidget);
      await type(tester, 8);
      await tester.tap(primary);
      await tester.pumpAndSettle();

      final round = games.currentRounds.single;
      expect(games.getScore(playerNamed('Ann').id!, round.id!), 0);
      expect(games.getScore(playerNamed('Bob').id!, round.id!), 8);
    });

    testWidgets('is a plain 0 for Tarot', (tester) async {
      await gameTypes.loadGameTypes();
      final tarot = await aType('tarot');
      await openBoard(tester, ['Ann', 'Bob'], typeId: tarot);
      await openRound(tester);

      expect(find.text(l10n.keypadZeroZapZap), findsNothing);
      expect(find.byKey(const Key('keypad_zapzap')), findsNothing);
      expect(find.byKey(const Key('keypad_digit_0')), findsOneWidget);
    });
  });

  testWidgets('a round skips the players already out of the game',
      (tester) async {
    await gameTypes.loadGameTypes();
    final type = await aType('custom', eliminates: true);
    await openBoard(tester, ['Ann', 'Bob', 'Cid'], typeId: type, rounds: [
      [10, 120, 30],
    ]);
    await openRound(tester);

    final bob = playerNamed('Bob');
    expect(find.byKey(Key('keypad_chip_${bob.id}')), findsNothing);
    await tester.tap(primary); // Ann
    await tester.pumpAndSettle();
    expect(find.text(l10n.keypadValidateRound), findsOneWidget); // Cid
    await tester.tap(primary);
    await tester.pumpAndSettle();

    final round = games.currentRounds.last;
    expect(games.getScore(bob.id!, round.id!), isNull);
    expect(games.getScore(playerNamed('Cid').id!, round.id!), 0);
  });

  testWidgets('from five players the caption says where the round is',
      (tester) async {
    await openBoard(tester, ['Ann', 'Bob', 'Cid', 'Dan', 'Eve']);
    await openRound(tester);
    expect(find.text(l10n.keypadCaptionWithPosition('Ann', 1, 1, 5)),
        findsOneWidget);
  });
}
