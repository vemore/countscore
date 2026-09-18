# The game-type list sorts on the stored name, not the one it shows

- **Noted:** 2026-09-16 — code review of `feat/game-types-long-tail` (#75)
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

Since #75 a built-in game type's *displayed* name comes from `game_types.builtin_key`
(`lib/utils/game_type_name.dart`), but `DriftGameTypeRepository.getAll`
(`lib/repositories/drift/drift_repositories.dart:216`) still orders `BY name ASC` on the
stored literal. So a Japanese user reads a list ordered by French spellings: `ウノ` before
`スカイジョ` because "Autre" sorts before "Belote". Every screen that lists types inherits it —
the game-types screen, the create-game dropdown.

It was left alone in #75 on purpose: sorting by the displayed name means either localizing
inside the repository layer, which has no `BuildContext` and no business having one, or
sorting in each screen after the fetch and giving up a stable order across them. That is a
design decision, not a fix to slip into a migration pull request.

**Fix:** decide where the collation belongs. The cheapest honest option is to sort in the
screens, with a shared helper next to `gameTypeDisplayName` that takes the `AppLocalizations`
and a `List<GameType>` and returns them ordered — and to drop the `ORDER BY` from `getAll`
rather than leave a misleading one. Use `intl`'s locale-aware comparison, not `String.compareTo`,
or `ヴ` and `ば` land in code-point order.

**Acceptance:**
- In `ja`, the game-types screen lists types in the collation order of their displayed names.
- The create-game dropdown and the home filter use the same order (one shared helper; the sort happens in the screens, as the entry recommends).
- A unit test of the helper covers at least two locales, kana among them.
- A custom type (no `builtinKey`) sorts by its stored name among the built-in ones.
