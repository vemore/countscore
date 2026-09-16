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
