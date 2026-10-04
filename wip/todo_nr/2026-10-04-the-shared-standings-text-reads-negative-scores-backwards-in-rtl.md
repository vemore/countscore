# The shared standings text can read a negative total backwards in Arabic and Urdu

- **Noted:** 2026-10-04 — while isolating negative scores for `fix/rtl-negative-scores`
- **Theme:** i18n
- **Area:** app
- **Blocks release:** no

`shareResultStanding` (`lib/l10n/app_fr.arb`) takes `points` as an `int` because its plural
selects on it, so `GameResultShare` (`lib/utils/game_result_share.dart:55`) cannot hand it the
isolated string `scoreText` gives the on-screen widgets. In `ar` and `ur` a negative total in
the shared text can therefore still read `25-`.

**Fix:** pass the number as a second, `String` placeholder used in the sentence while the `int`
one only drives the plural, or wrap the isolate in the plural branches of the `ar` and `ur`
files only.

**Acceptance:**
- A test on `GameResultShare` in `ar` and `ur` finds the isolated `-25` in the shared standings line.
