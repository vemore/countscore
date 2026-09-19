// The dice roller rolls 1 to 6 six-sided dice and shows each face and the
// total. A seeded Random makes the rolls reproducible: every value is 1..6 and
// the total shown is their sum, for every count and after every re-roll.

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
}
