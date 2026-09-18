import '../l10n/app_localizations.dart';
import '../models/game_type.dart';

/// The name to show for a game type.
///
/// `builtinKey` carries the identity **and** the displayed name; `name` is only
/// read for rows whose `builtinKey` is null. That is what makes the stored name
/// of a built-in type inconsequential: two devices in different locales hold
/// different names for the same row and still agree on what it is, so
/// last-writer-wins on that column is harmless. See .llmwiki/I18n.md.
///
/// Renaming a built-in type clears its key (`game_types_screen.dart`), so from
/// then on the user's chosen name is what this returns.
String gameTypeDisplayName(AppLocalizations l10n, GameType type) =>
    builtinGameTypeName(l10n, type.builtinKey) ?? type.name;

/// The localized name of a built-in key, or null for an unknown or absent key —
/// including a key a *newer* version of the app seeded and this one does not
/// know, which a pulled delta can carry.
///
/// `AppLocalizations` offers no lookup by name, so the switch is explicit. Every
/// key in `GameType.defaultGameTypes()` must have a case here;
/// `test/utils/game_type_name_test.dart` fails if one is missing.
String? builtinGameTypeName(AppLocalizations l10n, String? builtinKey) {
  switch (builtinKey) {
    case 'zapzap':
      return l10n.gameTypeNameZapzap;
    case 'uno':
      return l10n.gameTypeNameUno;
    case 'scrabble':
      return l10n.gameTypeNameScrabble;
    case 'other':
      return l10n.gameTypeNameOther;
    case 'skyjo':
      return l10n.gameTypeNameSkyjo;
    case 'president':
      return l10n.gameTypeNamePresident;
    case 'belote':
      return l10n.gameTypeNameBelote;
    case 'tarot':
      return l10n.gameTypeNameTarot;
    case 'bridge':
      return l10n.gameTypeNameBridge;
    case 'rami':
      return l10n.gameTypeNameRami;
    case 'coinche':
      return l10n.gameTypeNameCoinche;
    case 'yahtzee':
      return l10n.gameTypeNameYahtzee;
    case 'phase10':
      return l10n.gameTypeNamePhase10;
    case 'flip7':
      return l10n.gameTypeNameFlip7;
    case 'mille_bornes':
      return l10n.gameTypeNameMilleBornes;
    case 'rummikub':
      return l10n.gameTypeNameRummikub;
    case 'six_nimmt':
      return l10n.gameTypeNameSixNimmt;
    case 'qwirkle':
      return l10n.gameTypeNameQwirkle;
    case 'farkle':
      return l10n.gameTypeNameFarkle;
    case 'canasta':
      return l10n.gameTypeNameCanasta;
    case 'wizard':
      return l10n.gameTypeNameWizard;
    case 'triomino':
      return l10n.gameTypeNameTriomino;
    default:
      return null;
  }
}

/// Whether saving [typedName] over [type] gives up its built-in key.
///
/// It does when, and only when, the user actually changed the name of a built-in
/// type: the key is what the displayed name is read from, so keeping it would
/// silently ignore what they typed. Everything else — the icon, the colour, a
/// threshold — may change with the key intact.
///
/// **Trimmed on both sides.** A stray trailing space typed while changing the
/// colour is not a rename, and treating it as one is destructive: the type stops
/// being localized, and for ZapZap it turns the analysis feature off outright
/// (`game_board_screen.dart` keys that on `builtinKey == 'zapzap'`).
bool isBuiltinRename(AppLocalizations l10n, GameType type, String typedName) =>
    type.builtinKey != null &&
    typedName.trim() != gameTypeDisplayName(l10n, type).trim();

/// The name to show for a value the statistics aggregate grouped by, which is
/// `COALESCE(game_types.builtin_key, game_types.name)` — a built-in key when the
/// game was played on a built-in type, the stored name otherwise.
///
/// A **last resort**: it can only return the raw key for a built-in key this
/// version does not know. A caller holding the row should use
/// [gameTypeDisplayName], which falls back to the stored name instead.
String gameTypeDisplayNameForKey(AppLocalizations l10n, String keyOrName) =>
    builtinGameTypeName(l10n, keyOrName) ?? keyOrName;

/// [types] ordered by the name the user reads, for every screen that lists game
/// types: the game-types screen, the create-game dropdown, the home filter and
/// the board's edit dialog.
///
/// The sort lives here and not in `GameTypeRepository.getAll`, which returns
/// rows in no particular order: the repository has no `AppLocalizations`, and
/// ordering on the stored `name` sorted a Japanese list by its French spellings.
/// A custom type (no `builtinKey`) sorts by its stored name among the built-in
/// ones, since that is what [gameTypeDisplayName] shows for it.
///
/// A new list is returned; [types] is left as it was.
List<GameType> sortGameTypesByDisplayName(
    AppLocalizations l10n, Iterable<GameType> types) {
  final keyed = [
    for (final t in types) (type: t, name: gameTypeDisplayName(l10n, t)),
  ];
  keyed.sort((a, b) => collateNames(a.name, b.name));
  return [for (final k in keyed) k.type];
}

/// Compares two display names the way a reader expects, not by code point.
///
/// Neither the SDK nor `intl` ships a collator (`intl` formats, it does not
/// sort), and the packages that do bring ICU data or native assets to both the
/// APK and the PWA — for a list of about twenty names. So this is a small
/// approximation of the Unicode Collation Algorithm's levels, enough for the
/// scripts the ten locales name game types in:
///
/// 1. **Primary** — case and accents folded (`É` = `e`, `ß` = `ss`, `ё` = `е`),
///    katakana folded onto hiragana, voiced and small kana onto their base
///    (`バ` = `は`, `ヴ` = `う`, `ィ` = `い`), and the long-vowel mark `ー` read
///    as the vowel it lengthens, as Japanese dictionaries order it.
/// 2. **Secondary** — the lowercased name with its accents and kana marks, so
///    `Belote` < `Bélote` and `は` < `ば`.
/// 3. **Tertiary** — the raw string, so the order is total and stable.
///
/// Han characters keep their code-point order: a Chinese list is not in pinyin
/// order, which only real collation data can give.
int collateNames(String a, String b) {
  final primary = _primaryKey(a).compareTo(_primaryKey(b));
  if (primary != 0) return primary;
  final secondary = a.toLowerCase().compareTo(b.toLowerCase());
  if (secondary != 0) return secondary;
  return a.compareTo(b);
}

String _primaryKey(String s) {
  final out = StringBuffer();
  int? previous; // the last base hiragana written, which `ー` lengthens
  for (final rune in s.toLowerCase().runes) {
    final latin = _latinFold[rune];
    if (latin != null) {
      out.write(latin);
      previous = null;
      continue;
    }
    if (rune == 0x0451) {
      // ё sorts with е in Russian dictionaries.
      out.writeCharCode(0x0435);
      previous = null;
      continue;
    }
    if (rune == 0x30FC && previous != null) {
      final vowel = _kanaVowel[previous];
      if (vowel != null) {
        out.writeCharCode(vowel);
        continue;
      }
    }
    final kana = _foldKana(rune);
    out.writeCharCode(kana);
    previous = kana >= 0x3041 && kana <= 0x3096 ? kana : null;
  }
  return out.toString();
}

/// A katakana onto its hiragana, then a voiced or small kana onto its base.
int _foldKana(int rune) {
  var r = rune;
  if (r >= 0x30A1 && r <= 0x30F6) r -= 0x60; // katakana block → hiragana
  return _kanaBase[r] ?? r;
}

const _latinFold = <int, String>{
  0xE0: 'a', 0xE1: 'a', 0xE2: 'a', 0xE3: 'a', 0xE4: 'a', 0xE5: 'a', //
  0xE6: 'ae', 0xE7: 'c', //
  0xE8: 'e', 0xE9: 'e', 0xEA: 'e', 0xEB: 'e', //
  0xEC: 'i', 0xED: 'i', 0xEE: 'i', 0xEF: 'i', //
  0xF1: 'n', //
  0xF2: 'o', 0xF3: 'o', 0xF4: 'o', 0xF5: 'o', 0xF6: 'o', 0xF8: 'o', //
  0xF9: 'u', 0xFA: 'u', 0xFB: 'u', 0xFC: 'u', //
  0xFD: 'y', 0xFF: 'y', 0xDF: 'ss', 0x153: 'oe', //
};

/// Voiced (゛), semi-voiced (゜) and small hiragana onto their base kana.
final Map<int, int> _kanaBase = () {
  final map = <int, int>{};
  void shifted(String bases, int step) {
    for (final b in bases.runes) {
      map[b + step] = b;
    }
  }

  shifted('かきくけこさしすせそたちつてと', 1); // が … ど
  shifted('はひふへほ', 1); // ば … ぼ
  shifted('はひふへほ', 2); // ぱ … ぽ
  shifted('あいうえおつやゆよわ', -1); // ぁ … ゎ: a small kana precedes its base
  map[0x3094] = 0x3046; // ゔ → う
  map[0x3095] = 0x304B; // ゕ → か
  map[0x3096] = 0x3051; // ゖ → け
  return map;
}();

/// The vowel each base hiragana ends in, which is what `ー` repeats.
final Map<int, int> _kanaVowel = () {
  final vowels = 'あいうえお'.runes.toList();
  const rows = [
    'あいうえお', 'かきくけこ', 'さしすせそ', 'たちつてと', 'なにぬねの', //
    'はひふへほ', 'まみむめも', 'らりるれろ',
  ];
  final map = <int, int>{};
  for (final row in rows) {
    final kana = row.runes.toList();
    for (var i = 0; i < kana.length; i++) {
      map[kana[i]] = vowels[i];
    }
  }
  map[0x3084] = 0x3042; // や
  map[0x3086] = 0x3046; // ゆ
  map[0x3088] = 0x304A; // よ
  map[0x308F] = 0x3042; // わ
  map[0x3092] = 0x304A; // を
  return map;
}();
