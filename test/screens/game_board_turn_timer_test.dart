// The board's turn timer: in the overflow menu, it counts down from the chosen
// duration, says so at zero, resets, and reopens on the last duration chosen
// for the game's type (wip/done/2026-09-18-no-turn-timer-on-the-board.md).
//
// The menu is read through its `itemBuilder` and driven through `onSelected`,
// as in `game_board_dice_test.dart`: a Material popup overflows its 256 px
// under the test font.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/services/game_sounds.dart';
import 'package:countscore/widgets/turn_timer_dialog.dart';

import '../support/board_harness.dart';

void main() {
  late BoardHarness board;
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    board = BoardHarness();
  });

  tearDown(() => board.close());

  final menu = find.byType(PopupMenuButton<String>);
  final value = find.byKey(const Key('turn_timer_value'));
  final timeUp = find.byKey(const Key('turn_timer_time_up'));

  String shown(WidgetTester tester) => tester.widget<Text>(value).data!;

  Future<void> openTimer(WidgetTester tester) async {
    tester.widget<PopupMenuButton<String>>(menu).onSelected!('turn_timer');
    await tester.pumpAndSettle();
    expect(find.text(l10n.turnTimer), findsOneWidget);
  }

  Future<void> closeTimer(WidgetTester tester) async {
    await tester.tap(find.text(l10n.close));
    await tester.pumpAndSettle();
    expect(value, findsNothing);
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pump();
  }

  testWidgets('the overflow menu has the turn timer, next to the dice',
      (tester) async {
    await board.aGame(['Ann', 'Bob']);
    await board.open(tester);

    final button = tester.widget<PopupMenuButton<String>>(menu);
    final values = [
      for (final item in button.itemBuilder(tester.element(menu)))
        if (item is PopupMenuItem<String>) item.value,
    ];
    expect(values.indexOf('turn_timer'), values.indexOf('roll_dice') + 1);
  });

  testWidgets('it counts down to zero, signals it, and resets',
      (tester) async {
    await board.aGame(['Ann', 'Bob']);
    await board.open(tester);
    await openTimer(tester);

    expect(shown(tester), '1:00',
        reason: 'a type with no duration yet starts on the default');
    await tap(tester, 'turn_timer_less');
    await tap(tester, 'turn_timer_less');
    await tap(tester, 'turn_timer_less');
    expect(shown(tester), '0:15');

    await tap(tester, 'turn_timer_start');
    expect(find.text(l10n.turnTimerPause), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(shown(tester), '0:10');

    // Paused, it holds.
    await tap(tester, 'turn_timer_start');
    await tester.pump(const Duration(seconds: 5));
    expect(shown(tester), '0:10');

    await tap(tester, 'turn_timer_start');
    await tester.pump(const Duration(seconds: 9));
    expect(shown(tester), '0:01');
    expect(timeUp, findsNothing);
    await tester.pump(const Duration(seconds: 1));
    expect(shown(tester), '0:00');
    expect(timeUp, findsOneWidget);
    expect(find.text(l10n.turnTimerTimeUp), findsOneWidget);
    expect(find.text(l10n.turnTimerStart), findsOneWidget,
        reason: 'it stops at zero');
    await tester.pump(const Duration(seconds: 3));
    expect(shown(tester), '0:00');
    expect(board.sounds.played, isEmpty, reason: 'game sounds are off');

    await tap(tester, 'turn_timer_reset');
    expect(shown(tester), '0:15');
    expect(timeUp, findsNothing);
    await closeTimer(tester);
  });

  testWidgets('with game sounds on, zero plays the timer sound',
      (tester) async {
    SharedPreferences.setMockInitialValues({GameSounds.enabledKey: true});
    await board.aGame(['Ann', 'Bob']);
    await board.open(tester);
    await openTimer(tester);
    for (var i = 0; i < 3; i++) {
      await tap(tester, 'turn_timer_less');
    }
    await tap(tester, 'turn_timer_start');
    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(timeUp, findsOneWidget);
    expect(board.sounds.played, [GameSound.timerEnd]);
    await closeTimer(tester);
  });

  testWidgets('two game types each reopen the timer on their own last duration',
      (tester) async {
    final typeA = await board.aType();
    final typeB = await board.aType();

    await board.aGame(['Ann', 'Bob'], typeId: typeA);
    await board.open(tester);
    await openTimer(tester);
    await tap(tester, 'turn_timer_more'); // 1:15
    await tap(tester, 'turn_timer_more'); // 1:30
    await closeTimer(tester);

    await board.aGame(['Ann', 'Bob'], typeId: typeB);
    await tester.pumpAndSettle();
    await openTimer(tester);
    expect(shown(tester), '1:00');
    await tap(tester, 'turn_timer_less'); // 0:45
    await closeTimer(tester);

    await board.aGame(['Cid', 'Dan'], typeId: typeA);
    await tester.pumpAndSettle();
    await openTimer(tester);
    expect(shown(tester), '1:30');
    await closeTimer(tester);

    await board.aGame(['Cid', 'Dan'], typeId: typeB);
    await tester.pumpAndSettle();
    await openTimer(tester);
    expect(shown(tester), '0:45');
    await closeTimer(tester);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(TurnTimerDialog.prefsKey(typeA)), 90);
    expect(prefs.getInt(TurnTimerDialog.prefsKey(typeB)), 45);
  });
}
