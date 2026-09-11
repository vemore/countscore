---
name: i18n-add-string
description: Add, rename, or remove a user-facing string in the CountScore Flutter app across all 10 languages. Use whenever new text must appear in the UI, when a label needs rewording, when a hardcoded string is found in a widget, or when adding a plural or a parameterized message. Triggers: "add a string", "ajouter une traduction", "nouveau texte", "translate this label", "hardcoded string", "add a language", "plural form", "gen-l10n".
---

# Adding a localized string to CountScore

Ten ARB files must stay in lockstep: **180 keys each**, no gaps. A missing key in one
language is a silent English fallback for those users.

## Layout

| Fact | Value |
|---|---|
| ARB files | `lib/l10n/app_{ar,de,en,es,fr,hi,ja,pt,ru,zh}.arb` |
| **Template** | `app_fr.arb` — French. Carries the `@key` metadata. |
| **Runtime fallback** | `en` |
| Generated | `lib/l10n/app_localizations*.dart` — committed, never hand-edited |
| Config | `l10n.yaml` (3 lines) |

The template and the fallback are **different files**. Metadata goes in French; English is
what an unsupported locale resolves to.

## Procedure

### 1. Add the key to all 10 ARB files

Put the `@key` description block **only in `app_fr.arb`**. The other nine get the bare
key/value pair.

`app_fr.arb`:
```json
"gameDeleted": "Partie supprimée",
"@gameDeleted": {
  "description": "Snackbar shown after a game is deleted"
}
```
`app_en.arb` and the other eight:
```json
"gameDeleted": "Game deleted"
```

Translate genuinely for each locale — do not leave English placeholders in `ar`, `hi`,
`ja`, `ru` or `zh`. For Arabic, remember the UI is RTL; avoid strings that assume
left-to-right ordering.

### 2. Placeholders

```json
"welcomeUser": "Bienvenue {userName}",
"@welcomeUser": {
  "description": "Greeting with the player's name",
  "placeholders": { "userName": { "type": "String", "example": "Alice" } }
}
```
Placeholder **names** are identical across all 10 files; only the surrounding text is
translated, and the placeholder may move within the sentence.

### 3. Plurals — never hand-rolled

`'$n item${n > 1 ? "s" : ""}'` is a defect. Use ICU:

```json
"roundCount": "{count, plural, =0{Aucune manche} =1{1 manche} other{{count} manches}}",
"@roundCount": {
  "description": "Number of rounds played",
  "placeholders": { "count": { "type": "int", "example": "5" } }
}
```

Required plural categories differ per language — supply every one the language needs:

| Languages | Categories needed |
|---|---|
| `zh`, `ja` | `other` only |
| `en`, `de`, `es`, `pt`, `hi` | `one`, `other` |
| `fr` | `one`, `other` (0 is singular in French) |
| `ru` | `one`, `few`, `many`, `other` |
| `ar` | `zero`, `one`, `two`, `few`, `many`, `other` |

Use `=0` / `=1` for exact-value overrides, and always include `other`.

### 4. Regenerate

```bash
flutter gen-l10n
```

### 5. Use it

```dart
import '../l10n/app_localizations.dart';
// in build():
final l10n = AppLocalizations.of(context)!;
Text(l10n.gameDeleted)
Text(l10n.welcomeUser('Alice'))
Text(l10n.roundCount(5))
```

### 6. Verify

```bash
python3 -c "
import json,glob
counts={f:len([k for k in json.load(open(f)) if not k.startswith('@')]) for f in sorted(glob.glob('lib/l10n/app_*.arb'))}
print(counts)
assert len(set(counts.values()))==1, 'ARB key counts diverge: '+str(counts)
print('OK — all files agree')"
flutter analyze
flutter test
```

## Rules

- Never hardcode user-facing text: `Text('Bonjour')` is a defect.
- Never translate user-generated content — player names, game-type names, scores.
- Keep dates and times on `intl`'s `DateFormat`; it is already locale-aware.
- Renaming a key means renaming it in all 10 files plus every call site.
- Removing a key means removing it from all 10, plus the `@key` block in `app_fr.arb`.

## Adding a whole new language

1. Copy `app_en.arb` to `lib/l10n/app_XX.arb` and translate all 180 strings.
2. Apply that language's plural categories from the table above.
3. **Add the locale to `main.dart` `supportedLocales`** — the list is duplicated there, and
   an ARB alone will never be selected.
4. `flutter gen-l10n`, then check the UI for text overflow in the longest strings.

Background: `.llmwiki/I18n.md`.
