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
  late AppLocalizations zh;

  setUpAll(() async {
    fr = await AppLocalizations.delegate.load(const Locale('fr'));
    ja = await AppLocalizations.delegate.load(const Locale('ja'));
    zh = await AppLocalizations.delegate.load(const Locale('zh'));
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

  test('every built-in key has a sort key: the name, or its pinyin in zh',
      () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      for (final type in GameType.defaultGameTypes()) {
        final name = builtinGameTypeName(l10n, type.builtinKey)!;
        final sortKey = builtinGameTypeSortKey(l10n, type.builtinKey);
        expect(sortKey, isNotNull, reason: '${type.builtinKey} in $locale');
        if (locale.languageCode == 'zh') {
          // A Han name is replaced by its reading; a Latin one is kept.
          final hasHan = name.runes.any((r) => r >= 0x4E00 && r <= 0x9FFF);
          expect(sortKey == name, !hasHan, reason: '$name → $sortKey');
          expect(sortKey!.runes.any((r) => r >= 0x4E00 && r <= 0x9FFF),
              isFalse,
              reason: '$name → $sortKey');
        } else {
          expect(sortKey, name, reason: '${type.builtinKey} in $locale');
        }
      }
    }
    expect(builtinGameTypeSortKey(zh, 'petanque'), isNull);
    expect(builtinGameTypeSortKey(zh, null), isNull);
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

    test('Chinese: pinyin order of the displayed names, not code points', () {
      // Code-point order would put 三角骨牌 first and 桥牌 after 拉米. Each Han
      // name sorts by its reading among the Latin ones: 贝洛特 (bei) between 6
      // and Coinche, 其他 (qi) before 桥牌 (qiao) syllable by syllable, and
      // 拉米 (mǐ) before 拉密 (mì) on the tone.
      expect(sorted(zh, GameType.defaultGameTypes()), [
        '6 nimmt!', '贝洛特', 'Coinche', '翻牌 7', 'Farkle', '阶段 10', //
        '凯纳斯特', '快艇骰子', '拉米', '拉密', 'Mille Bornes', '其他', '桥牌',
        'Qwirkle', '三角骨牌', 'Scrabble', 'Skyjo', '塔罗牌', 'UNO', 'Wizard',
        'ZapZap', '总统',
      ]);
    });

    test('Chinese: a custom name keeps its code-point order', () {
      // No reading is known for a name the user typed: a Latin one sorts among
      // the pinyin keys, a Han one after every Latin key.
      final inChinese = sorted(zh, [
        ...GameType.defaultGameTypes(),
        _type(name: 'Pétanque'),
        _type(name: '麻将'),
      ]);
      expect(inChinese.indexOf('Pétanque'), inChinese.indexOf('其他') - 1);
      expect(inChinese.last, '麻将');
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
