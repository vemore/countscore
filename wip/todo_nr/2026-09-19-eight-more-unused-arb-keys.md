# Eight more ARB keys are read by no screen

- **Noted:** 2026-09-19 — while adding `arb_keys.py --unused` in fix/i18n-cleanup
- **Theme:** i18n
- **Area:** app
- **Blocks release:** no

`python3 .claude/hooks/arb_keys.py --unused` lists eight template keys that no `.dart` file
under `lib/` or `test/` mentions outside the generated `app_localizations*.dart`:
`atLeast2PlayersRequired`, `filterByGameType`, `gameSettings`, `overallStatistics`,
`playerNumber`, `playersListSummary`, `predefined`, `selectPlayer`. They are translated in
ten languages and carried for nothing, like the eight fix/i18n-cleanup removed.

**Fix:** confirm each one is not built dynamically, then remove it from the ten ARB files
(and its `@` block in `app_fr.arb`) with the `i18n-add-string` skill, and `flutter gen-l10n`.

**Acceptance:**
- `python3 .claude/hooks/arb_keys.py --unused` exits 0.
- `python3 .claude/hooks/arb_keys.py` passes.
