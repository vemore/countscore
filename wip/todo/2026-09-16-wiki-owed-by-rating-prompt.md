# Three wiki pages and a README permission line no longer match the code

- **Noted:** 2026-09-16 — while building feat/rating-prompt, which was forbidden to edit `.llmwiki/`
- **Theme:** docs
- **Area:** docs
- **Blocks release:** no

`feat/rating-prompt` ran in parallel with `docs/store-listing-aso`, which owns `.llmwiki/**`,
so the pull request could not carry its own wiki updates. Three pages are now wrong:

- **`I18n.md`** — "10 languages, 235 keys each" (`rateApp` makes it **236**, verified by JSON
  key count in all ten files).
- **`Testing.md`** — the table has no row for `test/services/review_prompt_test.dart` (8 tests:
  the first-launch stamp, each guard refusing on its own, the happy path asking exactly once,
  the version and session locks, and an unavailable platform not burning the version). Its
  total, "89 tests pass in fifteen files", was **already stale** before this change: `flutter
  test` now reports **112 passing, 1 skipped, across 18 files**.
- **`MobileApp.md`** — `about_screen` is 175 lines there and **195** now (a "Rate CountScore"
  ListTile opening the Play listing through `url_launcher`); the page has no services section,
  so the new `lib/services/review_prompt.dart` and its `ReviewPromptService.instance` singleton
  — the second thing `main()` awaits before `runApp`, after the theme and the backend URL — are
  recorded nowhere; and "49 Dart files under `lib/`" is now 62 as counted by `find lib -name
  '*.dart'`, so whatever that number counted should be stated or dropped.

Separately, `README.md` Privacy says "The release build declares one Android permission,
`INTERNET`, … and nothing else". The merged manifest also carries
`com.vemore.countscore.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, a signature-level,
app-private permission injected by `androidx.core:core:1.18.0` (blame report,
`build/app/intermediates/manifest_merge_blame_file/…`). It predates this change and
`in_app_review` adds no permission at all — but the sentence is literally false.

**Fix:** update the three pages and their `Updated:` dates once `docs/store-listing-aso` has
merged, and reword the README sentence to name the one permission *the app declares* and
acknowledge the androidx-injected one.

**Acceptance:**
- `.llmwiki/Testing.md` lists `test/services/review_prompt_test.dart`, and its totals match a fresh `flutter test` run.
- `.llmwiki/MobileApp.md` records `ReviewPromptService` and where `main()` wires it.
- `.llmwiki/MobileApp.md` has no `lib/` file total and no `(N l.)` sizes; `lib/widgets/` names its three components; the counts pinned by code (10 locales, 6 providers) stay.
- README Privacy names INTERNET as the declared permission and acknowledges the signature permission androidx injects.

## Absorbed (2026-09-18, refinement)

From `2026-09-16-mobileapp-counts-drift-silently`: `.llmwiki/MobileApp.md` says "70 Dart files",
but `git ls-files lib | grep -c .dart` gives 66. It says `lib/widgets/` "holds exactly one"
component, and there are three (`player_picker_dialog`, `group_devices_sheet`,
`group_settings_section`). Its `(N l.)` sizes are wrong too, e.g. about_screen shows 175 but
has 196. The fix is to drop these bare counts and name what each directory holds, keeping the
counts pinned by code.
The I18n half of this entry has already been fixed: `I18n.md` says 294 keys, which is correct.
