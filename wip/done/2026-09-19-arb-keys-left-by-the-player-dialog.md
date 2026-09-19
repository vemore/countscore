# Eight ARB keys are no longer used by any screen

**Status:** done (2026-09-19) — closed by fix/i18n-cleanup. The eight keys and their `@` blocks are gone from the ten ARB files and the generated localizations, and `lowestScoreExample` left `SAME_AS_ENGLISH_OK`. `arb_keys.py --unused` now reports template keys no `.dart` file under `lib/` mentions (on demand, in no hook); it found eight more, filed as wip/todo_nr/2026-09-19-eight-more-unused-arb-keys.md.

- **Noted:** 2026-09-19 — while redrawing the New game screen (feat/new-game-screen)
- **Theme:** i18n
- **Area:** app
- **Blocks release:** no

The New game screen's redraw removed `lib/widgets/player_picker_dialog.dart` and the "Other"
win-rule card. Their keys stay in all ten ARB files and in the generated localizations, read
by nothing in `lib/`: `selectPlayerDialogTitle`, `searchOrCreate`, `createNewPlayer`,
`allPlayersSelected`, `createGame`, `winRule`, `lowestScoreExample`, `highestScoreExample`.
They were left in place because other pull requests were editing the ARB files in parallel.
Nothing checks for unused keys, so they would be translated and carried forever.

**Fix:** remove the eight keys from the ten ARB files (and their `@` blocks in `app_fr.arb`,
and `lowestScoreExample` from `SAME_AS_ENGLISH_OK` in `.claude/hooks/arb_keys.py`), then
`flutter gen-l10n`. Optionally have `arb_keys.py` report template keys no `.dart` file under
`lib/` mentions.

**Acceptance:** `grep -rE "l10n\.(selectPlayerDialogTitle|searchOrCreate|createNewPlayer|allPlayersSelected|createGame|winRule|lowestScoreExample|highestScoreExample)\b" lib` and the ARB files find none of them; `arb_keys.py` passes.
