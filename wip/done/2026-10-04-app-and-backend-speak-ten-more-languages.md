# The app and the AI analysis stop at ten languages

**Status:** done (2026-10-04) — closed by feat/ten-more-languages. Ten ARB files (454 keys), ten `rules_<l>.md` (21 rulesets), `supportedLocales`, `GameRulesCatalog.locales`, the comment-language picker and ten `LANGUAGES` rows with native directives; Haiku translations reviewed on form only. Verified: `arb_keys.py`, `flutter analyze`, `flutter test`, `pytest`..

- **Noted:** 2026-10-04 — the user asked for ten more languages, store listing included
- **Theme:** i18n
- **Area:** app
- **Blocks release:** no

The app ships `ar de en es fr hi ja pt ru zh` (`lib/l10n/`, `.llmwiki/I18n.md`). The ten
next most used on Google Play, by Android user base (no public per-language Play ranking
exists, so the choice is the user's, 2026-10-04): `id` Indonesian · `tr` Turkish · `it` Italian ·
`ko` Korean · `vi` Vietnamese · `th` Thai · `pl` Polish · `bn` Bengali · `ur` Urdu (RTL) · `nl` Dutch.

The language list is hardcoded in `lib/main.dart` `supportedLocales`,
`GameRulesCatalog.locales`, `GroupSettingsScreen.languages` (the AI comment language picker),
`backend/app/services/analysis/languages.py` `LANGUAGES`, `.claude/hooks/arb_keys.py`
`SAME_AS_ENGLISH_OK`, and a few tests that name the ten.

**Fix:** ten ARB files from the French master (all keys, ICU plurals per language: `other` for
id ko th vi, `one`/`other` for tr it nl bn ur, `one`/`few`/`many`/`other` for pl), ten
`assets/rules/rules_<l>.md` with the 21 rulesets, one `LANGUAGES` row per language with its
directive written in that language, the picker's endonyms, `flutter gen-l10n`. Bulk translation
per `i18n-add-string` §1b (one Haiku agent per locale). Deploy backend, then the PWA.

**Acceptance:**
- `python3 .claude/hooks/arb_keys.py` passes on 20 ARB files: same key set, no value left as
  the English string outside `SAME_AS_ENGLISH_OK`.
- `test/game_rules_catalog_test.dart` passes for the 20 locales (21 slugs, the scoring numbers).
- `resolve_language("tr-TR")` (and each new code) returns that language in the backend tests,
  and every directive is non-empty and not the English one.
- `flutter analyze` and `flutter test` are green; a device in Urdu mirrors the layout.
- The PWA renders th, bn, ur, ko and vi with no missing glyph (Chromium, 412×860).
