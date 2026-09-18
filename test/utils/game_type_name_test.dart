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

  group('sortGameTypesByDisplayName', () {
    List<String> sorted(AppLocalizations l10n, List<GameType> types) => [
          for (final t in sortGameTypesByDisplayName(l10n, types))
            gameTypeDisplayName(l10n, t),
        ];

    test('French: accents fold, digits first, the stored name is not read', () {
      final types = [
        ...GameType.defaultGameTypes(),
        _type(name: 'Pétanque'),
      ];
      expect(sorted(fr, types), [
        '6 qui prend', 'Autre', 'Belote', 'Bridge', 'Canasta', 'Coinche', //
        'Farkle', 'Flip 7', 'Mille Bornes', 'Pétanque', 'Phase 10',
        'Président', 'Qwirkle', 'Rami', 'Rummikub', 'Scrabble', 'Skyjo',
        'Tarot', 'Triomino', 'Uno', 'Wizard', 'Yahtzee', 'ZapZap',
      ]);
    });

    test('Japanese: dictionary order of the displayed kana, not code points',
        () {
      // Code-point order would put フリップ before ブリッジ (the voiced mark is
      // a separate code point after the base) and ラミィ before ラミー (ー sits
      // after the whole katakana block). A dictionary reads ブ as フ and ー as
      // the vowel it lengthens.
      expect(sorted(ja, GameType.defaultGameTypes()), [
        'ZapZap', 'ウィザード', 'ウノ', 'カナスタ', 'クワークル', 'コワンシュ', //
        'スカイジョ', 'スクラブル', 'その他', 'タロット', 'トライオミノ', 'ニムト',
        'ファークル', 'フェーズ 10', 'ブリッジ', 'フリップ 7', 'ベロット',
        'ミルボルヌ', 'ヤッツィー', 'ラミー', 'ラミィキューブ', '大富豪',
      ]);
    });

    test('a custom type sorts by its stored name among the built-in ones', () {
      final builtins = GameType.defaultGameTypes();
      final inFrench = sorted(fr, [...builtins, _type(name: 'belotte du jeudi')]);
      expect(inFrench.indexOf('belotte du jeudi'), inFrench.indexOf('Belote') + 1);

      // ヴ is read as ウ, and a hiragana name sorts with its katakana peers.
      final inJapanese =
          sorted(ja, [...builtins, _type(name: 'ヴィラ'), _type(name: 'かるた')]);
      expect(inJapanese.sublist(1, 4), ['ウィザード', 'ヴィラ', 'ウノ']);
      expect(inJapanese.indexOf('かるた'), inJapanese.indexOf('カナスタ') + 1);
    });

    test('the input list is left as it was', () {
      final types = GameType.defaultGameTypes();
      final before = [for (final t in types) t.builtinKey];
      sortGameTypesByDisplayName(ja, types);
      expect([for (final t in types) t.builtinKey], before);
    });

    test('ties break on accents, then case, so the order is total', () {
      expect(collateNames('Belote', 'Bélote'), lessThan(0));
      expect(collateNames('は', 'ば'), lessThan(0));
      expect(collateNames('ば', 'ぱ'), lessThan(0));
      expect(collateNames('Uno', 'uno'), isNot(0));
      expect(collateNames('Straße', 'strasse'), greaterThan(0));
      expect(collateNames('Straße', 'strat'), lessThan(0));
    });
  });
}
