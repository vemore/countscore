// The turn timer dialog keeps one layout whether it is stopped, running or at
// zero: on a 360 dp phone, in the languages with the longest labels, the
// dialog, the start / pause button, Reset and Close never move or change size
// between two taps, and nothing overflows
// (wip/done/2026-09-25-the-turn-timer-dialog-changes-shape-while-it-runs.md).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/services/game_sounds.dart';
import 'package:countscore/widgets/turn_timer_dialog.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget app(Locale locale) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const Key('open_timer'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => TurnTimerDialog(
                  gameTypeId: null,
                  initialSeconds: TurnTimerDialog.stepSeconds,
                  sounds: GameSounds(),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

  final dialogCard = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(Material),
  );
  const tracked = [
    'turn_timer_start',
    'turn_timer_reset',
    'turn_timer_close',
    'turn_timer_less',
    'turn_timer_more',
  ];

  Map<String, Rect> layout(WidgetTester tester) => {
        'dialog': tester.getRect(dialogCard.first),
        for (final key in tracked) key: tester.getRect(find.byKey(Key(key))),
      };

  for (final code in ['fr', 'de', 'ru']) {
    testWidgets('at 360 dp in $code, stopped, running and at zero look alike',
        (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 780 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(app(Locale(code)));
      await tester.tap(find.byKey(const Key('open_timer')));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
          tester.element(find.byType(TurnTimerDialog)))!;

      final stopped = layout(tester);
      expect(find.text(l10n.turnTimerStart), findsOneWidget);

      await tester.tap(find.byKey(const Key('turn_timer_start')));
      await tester.pump();
      expect(find.text(l10n.turnTimerPause), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(layout(tester), stopped, reason: 'running');

      await tester.pump(
          const Duration(seconds: TurnTimerDialog.stepSeconds - 1));
      await tester.pump();
      expect(find.text(l10n.turnTimerTimeUp), findsOneWidget);
      expect(layout(tester), stopped, reason: 'at zero');

      await tester.tap(find.byKey(const Key('turn_timer_reset')));
      await tester.pump();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('turn_timer_more')));
        await tester.pump();
      }
      expect(layout(tester), stopped, reason: 'a longer duration');

      expect(tester.takeException(), isNull, reason: 'nothing overflows');

      await tester.tap(find.byKey(const Key('turn_timer_close')));
      await tester.pumpAndSettle();
      expect(find.byType(TurnTimerDialog), findsNothing);
    });
  }
}
