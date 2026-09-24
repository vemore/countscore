// The board's optional sounds: a "death" on elimination and a victory when the
// rule ends the game, both behind the "Game sounds" setting, off by default —
// and with it off, not even the system alert the elimination used to play
// (wip/done/2026-09-23-no-optional-sound-on-elimination-and-victory.md).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/screens/standings_screen.dart';
import 'package:countscore/services/game_sounds.dart';

import '../support/board_harness.dart';

void main() {
  late BoardHarness board;
  late List<MethodCall> platformCalls;

  setUp(() {
    board = BoardHarness();
  });

  tearDown(() => board.close());

  /// Records every SystemSound.play the board makes.
  void recordSystemSounds(WidgetTester tester) {
    platformCalls = [];
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
  }

  group('with the setting off (the default)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets('nothing plays on an elimination, not even the system alert',
        (tester) async {
      recordSystemSounds(tester);
      final typeId = await board.aType(eliminatesOver: 100);
      await board.aGame(['Ann', 'Bob'], typeId: typeId);
      await board.open(tester);

      await board.enterRound(tester, [120, 20]);
      expect(board.games.getPlayerTotal(board.playerNamed('Ann').id!), 120);
      expect(board.sounds.played, isEmpty);
      // Material's button clicks are SystemSound.play too; the alert is not.
      expect(
          platformCalls.where((c) =>
              c.method == 'SystemSound.play' &&
              c.arguments == SystemSoundType.alert.toString()),
          isEmpty);
    });

    testWidgets('nothing plays when the rule ends the game', (tester) async {
      final typeId = await board.aType(overAt: 100);
      await board.aGame(['Ann', 'Bob'], typeId: typeId);
      await board.open(tester);

      await board.enterRound(tester, [150, 20]);
      expect(find.byType(StandingsScreen), findsOneWidget);
      expect(board.sounds.played, isEmpty);
    });
  });

  group('with the setting on', () {
    setUp(() => SharedPreferences.setMockInitialValues(
        {GameSounds.enabledKey: true}));

    testWidgets(
        'an elimination plays the death sound once; a correction that brings '
        'the player back and out again plays it again', (tester) async {
      final typeId = await board.aType(eliminatesOver: 100);
      await board.aGame(['Ann', 'Bob'], typeId: typeId);
      await board.open(tester);

      await board.enterRound(tester, [120, 20]);
      expect(board.sounds.played, [GameSound.elimination]);

      // Another round, which only Bob plays: nothing new.
      await board.enterRound(tester, [5]);
      expect(board.sounds.played, [GameSound.elimination]);

      // Corrected back under the threshold, then out again.
      await board.editScore(tester, 'Ann', 0, 50);
      expect(board.games.getPlayerTotal(board.playerNamed('Ann').id!), 50);
      expect(board.sounds.played, [GameSound.elimination]);
      await board.editScore(tester, 'Ann', 0, 150);
      expect(board.sounds.played, [GameSound.elimination, GameSound.elimination]);
    });

    testWidgets('reaching the end condition plays the victory sound once',
        (tester) async {
      final typeId = await board.aType(overAt: 100);
      await board.aGame(['Ann', 'Bob'], typeId: typeId);
      await board.open(tester);

      await board.enterRound(tester, [150, 20]);
      expect(find.byType(StandingsScreen), findsOneWidget);
      expect(board.sounds.played, [GameSound.victory]);
    });

    testWidgets('reopening a finished game plays nothing', (tester) async {
      final typeId = await board.aType(overAt: 100);
      await board.aGame(['Ann', 'Bob'], typeId: typeId, rounds: [
        [150, 20],
      ]);
      await board.games.setGameFinished(board.games.currentGame!.id!, true);
      await board.open(tester);

      expect(find.byType(StandingsScreen), findsNothing);
      expect(board.sounds.played, isEmpty);
    });

    testWidgets('"End game" by hand is not a victory', (tester) async {
      final typeId = await board.aType(overAt: 100);
      await board.aGame(['Ann', 'Bob'], typeId: typeId, rounds: [
        [10, 20],
      ]);
      await board.open(tester);

      final finder = find.byType(PopupMenuButton<String>);
      tester.widget<PopupMenuButton<String>>(finder).onSelected!('finish_game');
      await tester.pumpAndSettle();
      expect(find.byType(StandingsScreen), findsOneWidget);
      expect(board.sounds.played, isEmpty);
    });
  });
}
