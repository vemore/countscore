# The default game name is hardcoded in French

- **Noted:** 2026-09-19 — full test pass of the production PWA (fresh Chromium profiles, Playwright, fr-FR at 412 × 860)
- **Theme:** i18n
- **Area:** app
- **Blocks release:** no

`lib/screens/create_game_screen.dart:78` seeds `String defaultGameName = 'Partie 1';` and
`_incrementGameName` builds on it. A Japanese or Arabic user's first game is called
"Partie 1". It breaks the project's first non-negotiable (every user-facing string goes
through `AppLocalizations`). Seen on the PWA in `ja-JP`, where the board title reads
"Partie 1" among Japanese labels.

**Fix:** an ICU message `defaultGameName(n)` through `i18n-add-string`. `_incrementGameName`
keeps parsing a trailing number, whatever the language.

**Acceptance:**
- A widget test in `en` and `ja`: a first game is named from the localized message, not
  "Partie 1".
- `grep -n "'Partie" lib/` finds nothing.
