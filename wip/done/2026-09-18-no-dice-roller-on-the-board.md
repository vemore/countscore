# The board has no dice roller

**Status:** done (2026-09-19) — closed by feat/dice-roller. `lib/widgets/dice_roller_dialog.dart`, opened from the board's overflow menu right after **Who starts?**: 1–6 d6, each die and the total, four new ARB keys in the ten files; tested with a seeded `Random` in `test/widgets/dice_roller_dialog_test.dart`. No permission, schema or network change.

- **Noted:** 2026-09-18 — split out of `wip/done/2026-09-16-no-dice-timer-first-player-helpers.md` when feat/board-growth shipped **Who starts?** alone
- **Theme:** growth
- **Area:** app
- **Blocks release:** no

The 2026-09-18 refinement decided the three table helpers ship one pull request each:
**Who starts?** first (done, `lib/widgets/who_starts_dialog.dart`), then the dice roller and
the turn timer. The Yahtzee/Farkle long tail needs dice the user may not have at hand, and
"dé" / "dice roller" are words typed into Play search.

**Fix:** a dialog or sheet reachable from the board's overflow menu, next to **Who
starts?**: choose how many dice (1–6?) and which kind (d6 only, decided below), roll, show each die and the total. Everything local, every string
through `i18n-add-string`, no permission, schema or network change.

**Acceptance:**
- The board's overflow menu has a dice item that rolls the chosen dice and shows each value and the total.
- A widget test with a seeded `Random` checks the values are in range and the total is their sum.
- Every string exists in the ten ARB files; no permission, schema or network change.

**Decided (2026-09-18, refinement 4):** d6 only — no kind selector; choose 1–6 dice.
