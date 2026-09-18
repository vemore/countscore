import 'dart:io';

import 'package:countscore/services/game_rules_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// The net that the ARB files would otherwise give for free.
///
/// Shipped rules are Markdown assets rather than ARB keys (`.llmwiki/I18n.md`),
/// so nothing regenerates when a locale falls behind. These checks fail instead.
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
    };
    for (final locale in GameRulesCatalog.locales) {
      final sections = GameRulesCatalog.parse(read(locale));
      for (final entry in critical.entries) {
        final body = sections[entry.key]!
            .replaceAll(' ', '')
            .replaceAll(' ', '')
            .replaceAll(' 000', '000');
        for (final number in entry.value) {
          expect(RegExp('(?<![0-9])$number(?![0-9])').hasMatch(body), isTrue,
              reason: '$locale/${entry.key} lost the number $number');
        }
      }
    }
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
