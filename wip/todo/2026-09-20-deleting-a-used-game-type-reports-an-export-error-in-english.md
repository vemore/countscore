# Deleting a game type that has games reports "error during export", followed by an English sentence

- **Noted:** 2026-09-20 — reviewing the game-type editor at the user's request
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

`DriftGameTypeRepository.delete` (`lib/repositories/drift/drift_repositories.dart:254`) refuses
to remove a type that games still reference, by throwing

```dart
throw Exception('Cannot delete game type: $count games are using it');
```

`_deleteGameType` (`lib/screens/game_types_screen.dart:404`) catches it and shows

```dart
SnackBar(content: Text('${l10n.errorDuringExport} ${e.toString()}'))
```

So a user who deletes a type in use reads, in French, *"Erreur lors de l'export
Exception: Cannot delete game type: 3 games are using it"* — a label about an export that never
happened, glued to an untranslated English sentence with the `Exception:` prefix still on it.
The same in the nine other languages. It breaks the first non-negotiable in `CLAUDE.md`:
never put a user-facing string in the code.

The confirmation dialog before it (`l10n.confirmDeleteGame`) does not mention the games either,
so the refusal is the first the user hears of the rule.

**Fix:** a localized message that says the real thing — "N parties utilisent ce type, il ne
peut pas être supprimé" — through the `i18n-add-string` skill, with the count as an ICU plural.
Better still, ask the repository **before** offering the deletion: the confirmation dialog can
name the count and the *Supprimer* action can be refused up front, leaving the thrown exception
as the guard it is rather than as the user interface. `l10n.errorDuringExport` then disappears
from this file.

**Acceptance:**
- Deleting a type used by games shows a localized message naming the count, with no `Exception:` and no English.
- The plural is an ICU form (1 game / N games) in the ten languages.
- No `e.toString()` reaches a user-facing widget in `game_types_screen.dart`.
