// A negative score in a right-to-left locale: Arabic and Urdu put the "-" after
// the digits unless the number is isolated (`lib/utils/score_text.dart`,
// `wip/done/2026-10-04-negative-scores-read-backwards-in-urdu.md`). The results
// screen is covered in `standings_screen_test.dart`; this file has the helper,
// the board's score cell and the keypad.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/models/player.dart';
import 'package:countscore/utils/player_colors.dart';
import 'package:countscore/utils/score_text.dart';
import 'package:countscore/widgets/board_lanes.dart';
import 'package:countscore/widgets/score_keypad_sheet.dart';

final _players = [
  for (final (i, name) in ['Lionel', 'Laurent'].indexed)
    Player(id: i + 1, gameId: 1, name: name, orderIndex: i),
];

Widget _app(String language, Widget home) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [for (final l in ['en', 'ar', 'ur']) Locale(l)],
      locale: Locale(language),
      home: home,
    );

void main() {
  test('scoreText isolates a negative and leaves the rest alone', () {
    final negative = scoreText(-25);
    expect(negative.runes.first, 0x2066);
    expect(negative.runes.last, 0x2069);
    expect(negative.substring(1, negative.length - 1), '-25');
    expect(scoreText(25), '25');
    expect(scoreText(0), '0');
  });

  test('the keypad spells its minus the same way', () {
    final shown = keypadScoreText(negative: true, digits: '3');
    expect(shown.runes.first, 0x2066);
    expect(shown.runes.last, 0x2069);
    expect(shown.substring(1, shown.length - 1), '−3');
    expect(keypadScoreText(negative: false, digits: ''), '0');
    expect(keypadScoreText(negative: true, digits: ''), contains('−0'));
  });

  for (final language in ['ur', 'ar']) {
    testWidgets('in $language, the board cell shows -25 in logical order',
        (tester) async {
      await tester.pumpWidget(
          _app(language, const Scaffold(body: BoardScoreText(score: -25))));
      expect(find.text(scoreText(-25)), findsOneWidget);
      expect(find.text('-25'), findsNothing);
    });

    testWidgets('in $language, the keypad value and total after keep the sign',
        (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(
        language,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => ScoreKeypadSheet.round(
                context,
                players: _players,
                colors: playerColorsById(_players),
                totalsBefore: const {},
                roundNumber: 1,
                shortcut: GameType.zapzap().keypadShortcut,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      Future<void> tap(String key) async {
        await tester.tap(find.byKey(Key(key)));
        await tester.pump();
      }

      await tap('keypad_sign');
      await tap('keypad_digit_2');
      await tap('keypad_digit_5');

      String text(String key) =>
          tester.widget<Text>(find.byKey(Key(key))).data!;
      expect(text('keypad_value'),
          keypadScoreText(negative: true, digits: '25'));
      expect(text('keypad_total_after'), contains(scoreText(-25)));
    });
  }
}
