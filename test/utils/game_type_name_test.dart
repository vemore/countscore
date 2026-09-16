// `builtinKey` carries the identity AND the displayed name; `name` is only read
// for rows whose `builtinKey` is null.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countscore/l10n/app_localizations.dart';
import 'package:countscore/models/game_type.dart';
import 'package:countscore/utils/game_type_name.dart';

GameType _type({String? builtinKey, String name = 'stored'}) => GameType(
      builtinKey: builtinKey,
      name: name,
      iconCodePoint: 0,
      cardColorValue: 0,
      isLowestScoreWins: false,
    );

void main() {
  late AppLocalizations fr;
  late AppLocalizations ja;

  setUpAll(() async {
    fr = await AppLocalizations.delegate.load(const Locale('fr'));
    ja = await AppLocalizations.delegate.load(const Locale('ja'));
  });

  test('every built-in key has a case in the switch', () {
    for (final type in GameType.defaultGameTypes()) {
      expect(type.builtinKey, isNotNull, reason: type.name);
      expect(
        builtinGameTypeName(fr, type.builtinKey),
        isNotNull,
        reason: 'no localized name for ${type.builtinKey}',
      );
    }
  });

  test('the built-in keys are unique', () {
    final keys = GameType.defaultGameTypes().map((t) => t.builtinKey).toList();
    expect(keys.toSet(), hasLength(keys.length));
  });

  test('a built-in name comes from the locale, not from the stored name', () {
    final other = _type(builtinKey: 'other', name: 'Autre');
    expect(gameTypeDisplayName(fr, other), 'Autre');
    expect(gameTypeDisplayName(ja, other), 'その他');

    // The stored name is inconsequential for a built-in row: this is what makes
    // last-writer-wins on `name` harmless between two devices in two locales.
    final withForeignName = _type(builtinKey: 'other', name: 'Sonstiges');
    expect(gameTypeDisplayName(ja, withForeignName), 'その他');
  });

  test('a user type falls back to its stored name', () {
    expect(gameTypeDisplayName(ja, _type(name: 'Le jeu du jeudi')), 'Le jeu du jeudi');
  });

  test('an unknown key — one a newer app version seeded — falls back too', () {
    expect(gameTypeDisplayName(fr, _type(builtinKey: 'petanque', name: 'Pétanque')), 'Pétanque');
    expect(builtinGameTypeName(fr, 'petanque'), isNull);
  });

  group('isBuiltinRename', () {
    test('a stray space is not a rename', () {
      final zapzap = _type(builtinKey: 'zapzap', name: 'ZapZap');
      expect(isBuiltinRename(fr, zapzap, 'ZapZap'), isFalse);
      expect(isBuiltinRename(fr, zapzap, 'ZapZap '), isFalse);
      expect(isBuiltinRename(fr, zapzap, '  ZapZap'), isFalse);
    });

    test('the locale the user sees is the one compared against', () {
      // A Japanese user editing "その他" has not renamed anything; comparing
      // against the stored `Autre` would call every save a rename.
      final other = _type(builtinKey: 'other', name: 'Autre');
      expect(isBuiltinRename(ja, other, 'その他'), isFalse);
      expect(isBuiltinRename(ja, other, 'Autre'), isTrue);
    });

    test('a real rename gives up the key', () {
      expect(
        isBuiltinRename(fr, _type(builtinKey: 'skyjo', name: 'Skyjo'), 'Le jeu du jeudi'),
        isTrue,
      );
    });

    test('a type that has no key cannot give one up', () {
      expect(isBuiltinRename(fr, _type(name: 'Le jeu du jeudi'), 'Autre chose'), isFalse);
    });
  });

  test('the statistics key resolves the same way', () {
    expect(gameTypeDisplayNameForKey(ja, 'yahtzee'), 'ヤッツィー');
    expect(gameTypeDisplayNameForKey(ja, 'Le jeu du jeudi'), 'Le jeu du jeudi');
    expect(gameTypeDisplayNameForKey(ja, 'Unknown'), 'Unknown');
  });
}
