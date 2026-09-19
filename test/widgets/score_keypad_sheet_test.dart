// The keypad sheet draws its players as the board does (two letters), keeps
// 1 2 3 left to right in a right-to-left locale, and never breaks its tall
// key's label inside a word, in any of the ten locales
// (wip/done/2026-09-19-keypad-and-home-avatars-disagree-with-the-board.md,
// wip/done/2026-09-19-es-pt-labels-wrap-mid-word.md).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/utils/player_colors.dart';
import 'package:countscore/widgets/score_keypad_sheet.dart';

import '../support/label_lines.dart';

const _locales = ['ar', 'de', 'en', 'es', 'fr', 'hi', 'ja', 'pt', 'ru', 'zh'];

final _players = [
  for (final (i, name) in ['Lionel', 'Laurent', 'Sofia'].indexed)
    Player(id: i + 1, gameId: 1, name: name, orderIndex: i),
];

void main() {
  /// Opens the sheet in [locale] on a 412 × 860 phone: a round, or the one
  /// score of Laurent when [single].
  Future<void> open(WidgetTester tester, String locale,
      {bool single = false}) async {
    tester.view.physicalSize = const Size(412, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final colours = playerColorsById(_players);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [for (final l in _locales) Locale(l)],
      locale: Locale(locale),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => single
                ? ScoreKeypadSheet.single(
                    context,
                    players: _players,
                    colors: colours,
                    totalsBefore: const {},
                    roundNumber: 1,
                    isZapZap: false,
                    roundScores: const {1: 3, 2: 5, 3: 8},
                    playerId: 2,
                  )
                : ScoreKeypadSheet.round(
                    context,
                    players: _players,
                    colors: colours,
                    totalsBefore: const {},
                    roundNumber: 1,
                    isZapZap: true,
                  ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  RenderParagraph primaryLabel(WidgetTester tester) =>
      tester.renderObject<RenderParagraph>(find.descendant(
        of: find.byKey(const Key('keypad_primary_label')),
        matching: find.byType(RichText),
      ));

  testWidgets('the chips show the two letters the board shows',
      (tester) async {
    await open(tester, 'en');
    for (final (id, initials) in [(1, 'Li'), (2, 'La'), (3, 'So')]) {
      expect(
          find.descendant(
              of: find.byKey(Key('keypad_chip_$id')),
              matching: find.text(initials)),
          findsOneWidget,
          reason: initials);
    }
  });

  testWidgets('in French, the Save key reads on one line', (tester) async {
    await open(tester, 'fr', single: true);
    final label = primaryLabel(tester);
    expect(label.text.toPlainText(), 'Enregistrer');
    expect(lineCount(label), 1);
  });

  testWidgets('in Arabic, the digit grid still reads 1 2 3 from left to right',
      (tester) async {
    await open(tester, 'ar');
    double x(int d) =>
        tester.getCenter(find.byKey(Key('keypad_digit_$d'))).dx;
    expect(x(1), lessThan(x(2)));
    expect(x(2), lessThan(x(3)));
    expect(x(7), lessThan(x(9)));
    // The label keeps the locale's direction.
    expect(primaryLabel(tester).textDirection, TextDirection.rtl);
  });

  for (final locale in _locales) {
    testWidgets('$locale: no key label breaks inside a word', (tester) async {
      await open(tester, locale);
      // "Next: Laurent", then "Next: Sofia", then "Validate round".
      for (var step = 0; step < 3; step++) {
        final label = primaryLabel(tester);
        expect(wordsBrokenAcrossLines(label), isEmpty,
            reason: '$locale: "${label.text.toPlainText()}"');
        await tester.tap(find.byKey(const Key('keypad_primary')));
        await tester.pumpAndSettle();
        if (step == 2) break;
      }
      await open(tester, locale, single: true);
      final save = primaryLabel(tester);
      expect(wordsBrokenAcrossLines(save), isEmpty,
          reason: '$locale: "${save.text.toPlainText()}"');
    });
  }
}
