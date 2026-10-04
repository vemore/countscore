# A negative score reads "25-" in Urdu

**Status:** done (2026-10-04) — closed by fix/rtl-negative-scores: `scoreText`/`keypadScoreText` isolate a negative on the board, podium, list, keypad, Resume card and player card; tests in `negative_score_rtl_test.dart` and `standings_screen_test.dart`. The ur/ar Play screenshots are retaken in a later commit of the same pull request, which is not merged before.

- **Noted:** 2026-10-04 — reading the Urdu Play screenshots (results screen, ranking rows)
- **Theme:** i18n
- **Area:** app
- **Blocks release:** no

In `ur` (RTL) the podium and the ranking show -25, -50, -95 as `25-`, `50-`, `95-`: the minus sign
lands after the digits under the bidirectional algorithm, which reads as a trailing dash and,
for a score, as a different number. Arabic uses the same mechanism and is probably affected
too (`ar` is not in the 2026-10-04 captures, nothing was checked there).

**Fix:** render scores with an explicit LTR isolate (`⁦…⁩`, or `Directionality(textDirection: ltr)` around the number) wherever a score or a total is shown; check `ar` and `ur` on the board, the results screen, the keypad ("total after") and the statistics.

**Acceptance:**
- A widget test pumps the results screen and the board in `ur` and `ar` and finds `-25` in logical order.
- The Urdu and Arabic Play screenshots are retaken for the screens where a negative score appears.
