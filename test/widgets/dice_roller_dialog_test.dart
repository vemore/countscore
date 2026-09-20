// The dice roller rolls 1 to 6 six-sided dice and shows each face and the
// total. A seeded Random makes the rolls reproducible: every value is 1..6 and
// the total shown is their sum, for every count and after every re-roll.
// The six count choices also have to sit on a single row inside the dialog on a
// 412 dp phone — the geometry, not merely the presence of six widgets.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/widgets/dice_roller_dialog.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Widget wrap(Random random) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        locale: const Locale('en', ''),
        home: Scaffold(body: DiceRollerDialog(random: random)),
      );

  Widget showDialogApp(Random random) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        locale: const Locale('en', ''),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const Key('open_dice_roller'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => DiceRollerDialog(random: random),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

  List<int> dice(WidgetTester tester) => [
        for (var i = 0; i < DiceRollerDialog.maxDice; i++)
          if (find.byKey(Key('dice_value_$i')).evaluate().isNotEmpty)
            int.parse(tester
                .widget<Text>(find.descendant(
                  of: find.byKey(Key('dice_value_$i')),
                  matching: find.byType(Text),
                ))
                .data!),
      ];

  String total(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('dice_total'))).data!;

  void expectConsistent(WidgetTester tester, int count) {
    final values = dice(tester);
    expect(values, hasLength(count));
    for (final v in values) {
      expect(v, inInclusiveRange(1, 6));
    }
    expect(total(tester), l10n.diceTotal(values.fold(0, (s, v) => s + v)));
  }

  testWidgets('rolls the chosen number of d6, each 1..6, total = sum',
      (tester) async {
    await tester.pumpWidget(wrap(Random(42)));
    expect(find.text(l10n.diceRoller), findsOneWidget);
    expectConsistent(tester, 2);

    final seen = <int>{};
    for (var n = 1; n <= DiceRollerDialog.maxDice; n++) {
      await tester.tap(find.byKey(Key('dice_count_$n')));
      await tester.pump();
      expectConsistent(tester, n);
      for (var r = 0; r < 10; r++) {
        await tester.tap(find.byKey(const Key('dice_roll_again')));
        await tester.pump();
        expectConsistent(tester, n);
        seen.addAll(dice(tester));
      }
    }
    expect(seen, {1, 2, 3, 4, 5, 6},
        reason: 'two hundred rolled dice show every face');
  });

  testWidgets('the same seed rolls the same dice', (tester) async {
    await tester.pumpWidget(wrap(Random(7)));
    final first = dice(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(wrap(Random(7)));
    expect(dice(tester), first);
  });

  // The sixth chip used to wrap onto a line of its own (1 2 3 4 5 / 6) because
  // AlertDialog sizes its column with IntrinsicWidth and a Wrap's intrinsic
  // width ignores its own spacing. Assert the laid-out geometry, not that six
  // widgets exist: one row means one distinct top edge.
  for (final view in const [
    (label: '412 dp phone', size: Size(412, 915)),
    (label: 'PWA at 1600 px', size: Size(1600, 900)),
  ]) {
    testWidgets('the six count choices sit on one row — ${view.label}',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = view.size;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(showDialogApp(Random(3)));
      await tester.tap(find.byKey(const Key('open_dice_roller')));
      await tester.pumpAndSettle();

      final rects = <Rect>[];
      for (var n = 1; n <= DiceRollerDialog.maxDice; n++) {
        final finder = find.byKey(Key('dice_count_$n'));
        expect(finder, findsOneWidget);
        rects.add(tester.getRect(finder));
      }

      expect(
        rects.map((r) => r.top).toSet(),
        hasLength(1),
        reason: 'the six count choices share one row on a ${view.label}, '
            'but they landed at $rects',
      );

      // In order, left to right, and on the surface of the dialog.
      final surface = tester.getRect(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(Material),
            )
            .first,
      );
      for (var i = 0; i < rects.length; i++) {
        expect(rects[i].left, greaterThanOrEqualTo(surface.left - 0.01));
        expect(rects[i].right, lessThanOrEqualTo(surface.right + 0.01));
        if (i > 0) {
          expect(rects[i].left, greaterThanOrEqualTo(rects[i - 1].right));
        }
      }

      // Still usable at that width: the last choice rolls six dice.
      await tester.tap(find.byKey(const Key('dice_count_6')));
      await tester.pumpAndSettle();
      expect(dice(tester), hasLength(6));
    });
  }
}
