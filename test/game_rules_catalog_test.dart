import 'dart:io';

import 'package:countscore/services/game_rules_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// The net that the ARB files would otherwise give for free.
///
/// Shipped rules are Markdown assets rather than ARB keys (`.llmwiki/I18n.md`),
/// so nothing regenerates when a locale falls behind. These checks fail instead.
/// A space (plain, no-break or narrow no-break), comma, period or apostrophe
/// between a digit and a group of exactly three digits.
final _thousandsSeparator =
    RegExp('(?<=[0-9])[ \u00A0\u202F,.\'](?=[0-9]{3}(?![0-9]))');

void main() {
  String read(String locale) =>
      File('assets/rules/rules_$locale.md').readAsStringSync();

  test('every supported locale ships a rules asset', () {
    for (final locale in GameRulesCatalog.locales) {
      expect(File('assets/rules/rules_$locale.md').existsSync(), isTrue,
          reason: 'assets/rules/rules_$locale.md is missing');
    }
  });

  test('every locale defines exactly the expected slugs, none empty', () {
    for (final locale in GameRulesCatalog.locales) {
      final sections = GameRulesCatalog.parse(read(locale));
      expect(sections.keys.toSet(), GameRulesCatalog.slugs.toSet(),
          reason: '$locale does not define the expected rulesets');
      for (final entry in sections.entries) {
        expect(entry.value.trim(), isNotEmpty,
            reason: '$locale/${entry.key} is empty');
      }
    }
  });

  test('every locale keeps the thresholds the app scores on', () {
    // A translation that loses a number silently contradicts the game type it
    // documents, which is worse than shipping no rules at all.
    const critical = {
      'zapzap': ['100', '101', '25'],
      'uno': ['500', '50'],
      'skyjo': ['100', '12'],
      'president': ['10'],
      'belote': ['162', '81'],
      'tarot': ['56', '51', '41', '36'],
      'rami': ['51', '100'],
      // The long tail, shipped with schema v16. The seeded thresholds first.
      'coinche': ['1000', '80', '162', '160'],
      'yahtzee': ['13', '63', '35', '50'],
      'phase10': ['10', '15', '25'],
      'flip7': ['200', '15', '12'],
      'mille_bornes': ['5000', '1000', '400'],
      'rummikub': ['106', '14', '30'],
      'six_nimmt': ['66', '65', '104'],
      'qwirkle': ['108', '12'],
      'farkle': ['10000', '1000', '500'],
      'canasta': ['5000', '500', '300'],
      'wizard': ['60', '20'],
      'triomino': ['56', '40', '50', '25'],
    };
    for (final locale in GameRulesCatalog.locales) {
      final sections = GameRulesCatalog.parse(read(locale));
      for (final entry in critical.entries) {
        // Thousands separators differ per locale — 1 000, 1,000, 1.000 — and
        // are dropped before the numbers are looked up.
        final body = sections[entry.key]!
            .replaceAll(_thousandsSeparator, '');
        for (final number in entry.value) {
          expect(RegExp('(?<![0-9])$number(?![0-9])').hasMatch(body), isTrue,
              reason: '$locale/${entry.key} lost the number $number');
        }
      }
    }
  });

  test('the catalogue covers the 21 rulesets the seed names', () {
    expect(GameRulesCatalog.slugs, hasLength(21));
    expect(GameRulesCatalog.slugs.toSet(), hasLength(21));
  });

  test('every locale says the game ends when a total reaches the threshold',
      () {
    // `firstPlayerOver` is `>=` since 2026-09-19 (GameType.isGameOver). The
    // French and English texts are the masters: none of them may say that
    // the game stops once a total *exceeds* its threshold.
    final fr = GameRulesCatalog.parse(read('fr'));
    expect(fr['uno'], contains("dès qu'un total atteint 500"));
    expect(fr['president'], contains("qu'un total atteint 10"));
    final en = GameRulesCatalog.parse(read('en'));
    expect(en['uno'], contains('as soon as a total reaches\n500'));
    expect(en['president'], contains('as soon as a total reaches 10'));
  });

  test('the parser keys sections on their marker and drops the preamble', () {
    final sections = GameRulesCatalog.parse('''
ignored preamble
<!--@uno-->
## Setup
Seven cards.
<!--@skyjo-->
## Setup
Twelve cards.
''');
    expect(sections.keys, ['uno', 'skyjo']);
    expect(sections['uno'], '## Setup\nSeven cards.');
    expect(sections['skyjo'], '## Setup\nTwelve cards.');
  });

  test('an unknown slug or locale resolves to nothing rather than throwing',
      () async {
    final catalog = GameRulesCatalog();
    expect(await catalog.rules(null, 'fr'), isNull);
    expect(await catalog.rules('', 'fr'), isNull);
  });
}
