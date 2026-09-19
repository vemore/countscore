# The twelve new game types ship no ruleset

- **Noted:** 2026-09-16 — merging `feat/game-types-long-tail` (#75) onto the rules page (#77)
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

#77 gave every game type a rules page and shipped a ruleset for nine of the ten seeded
types, resolved through `game_types.rules_slug` and `assets/rules/rules_<locale>.md`. #75
then added twelve more seeded types — Coinche, Yahtzee, Phase 10, Flip 7, Mille Bornes,
Rummikub, Take 6, Qwirkle, Farkle, Canasta, Wizard, Triomino — and none of them carries a
`rulesSlug`, because no ruleset was written for them.

So a user who picks Yahtzee gets the scoring summary #77 derives from the type's own fields,
then the "write your own" empty state where the other nine show text. Nothing is broken —
that is exactly what `Autre` does — but the feature is now advertised on 9 of 22 types
instead of 9 of 10, and these twelve are the ones the store listing names.

The two halves fit together correctly otherwise: `rules_slug` is back-filled by seeded name
and `builtin_key` by seeded name plus `isDefault`, so the same row gets both, and renaming a
type keeps its rules (slug survives) while giving up its localized name (key cleared).

**Fix:** write the twelve rulesets the way #77 wrote the nine — researched and written for
this app, never copied from a published rulebook — add their slugs to `defaultRulesSlugs` (`lib/services/sync/sync_schema.dart:176-186`)
and to the twelve factories in `lib/models/game_type.dart`, and let
`test/game_rules_catalog_test.dart` hold the ten locales in step. Consider keying
`defaultRulesSlugs` on `builtin_key` rather than on the seeded name while doing it: the key
is now the stable identity and the name is not.

**Decided (2026-09-18, refinement):** re-key `defaultRulesSlugs` on `builtin_key`, with a
migration that back-fills `rules_slug` on the 12 existing rows (`db-migration` skill), and
ship the twelve rulesets in **one** pull request.

**Acceptance:**
- Each of the twelve seeded types opens a rules page with text in all ten locales; `test/game_rules_catalog_test.dart` covers 21 slugs.
- `defaultRulesSlugs` is keyed on `builtin_key`, not on the seeded name.
- A migration test back-fills `rules_slug` on the twelve rows of an existing database, and a renamed type keeps its slug.
