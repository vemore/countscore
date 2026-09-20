# Editing a game type erases its rules — the shipped ruleset and anything the user wrote

- **Noted:** 2026-09-20 — reported by the user, reproduced on the PWA built from `main`
- **Theme:** game-types
- **Area:** app
- **Blocks release:** yes — silent data loss: rules the user wrote by hand are gone with no warning and no undo

The edit dialog builds a **new** `GameType` from the form fields
(`lib/screens/game_types_screen.dart:367`) and never carries `rules`, `rulesSlug` or
`isDefault` over from the row being edited. `DriftGameTypeRepository.update`
(`lib/repositories/drift/drift_repositories.dart:239`) writes every column of `toMap()`, so
those three are written as `NULL` / `0`.

**Reproduced:** Game Types → ZapZap → *Game rules* shows the shipped ruleset. Game Types →
ZapZap → *Edit* → Game Over Condition `None` → `Last player over`, threshold 100 → *Edit*.
*Game rules* now shows "No rules yet" and the app-bar pencil is gone. Any save does it —
changing the colour, the icon or a threshold is enough; the user need not touch the rules.

The type keeps its `builtinKey`, so it is still displayed as ZapZap; only the link to
`assets/rules/` and the user's own text are lost. The loss syncs to the group like any other
column ([[Sync]]).

`isDefault` is not cosmetic either (found 2026-09-20, reviewing the editor): it is what the
schema migrations use to tell a row the app seeded from one the user wrote — the `rules_slug`
back-fill selects `WHERE isDefault = 1 AND rules_slug IS NULL`, and the name-based link does
the same (`lib/services/sync/sync_schema.dart:243`, `:293`). A type cleared by an edit is
skipped by every future back-fill of that shape, so the damage outlives the edit.

**Fix:** carry `rules`, `rulesSlug` and `isDefault` through the edit — build the saved row with
`existingGameType.copyWith(...)` instead of a fresh `GameType(...)`, so a column the dialog
does not show cannot be cleared by it. The user asks, on top of that, for the rules text to be
**offered for editing** when the conditions change rather than silently dropped: the dialog
could show "the rules still say X" and open the rules editor after saving.

**Acceptance:**
- Editing every field of a built-in type leaves `rules_slug` and `isDefault` untouched, and *Game rules* still shows the shipped ruleset (widget or repository test).
- Editing a type whose `rules` the user wrote leaves that text untouched.
- A repository test fails if a new column is added to `GameType` and the edit dialog drops it.

**Open question:** after changing an elimination or game-over condition, should the app offer
to open the rules editor so the text matches the new condition, or leave the two independent?
