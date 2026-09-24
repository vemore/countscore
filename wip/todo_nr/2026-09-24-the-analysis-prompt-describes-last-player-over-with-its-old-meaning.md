# The analysis prompt describes `lastPlayerOver` with its old meaning

- **Noted:** 2026-09-24 — independent review of #213 (fix/game-ends-on-last-player), point 7
- **Theme:** game-types
- **Area:** backend
- **Blocks release:** no — the commentary misstates the ending rule; no crash, no data at risk

`backend/app/services/analysis/game_rules.py:170-171` (`_GAME_OVER`) tells the model:

- `lastPlayerOver`: "The game ends once every player's total has gone above {threshold}."
- `lastPlayerUnder`: "The game ends once every player's total has fallen below {threshold}."

That was the pre-2026-09-20 implementation. Since
`wip/done/2026-09-20-the-last-player-standing-condition-is-mislabelled-misimplemented-and-unset.md`
the condition means **last player standing**: the game ends once every player *but one* is past
the threshold (`GameType.isGameOver`, `lib/models/game_type.dart`). Schema v20 (#213) now sets
`lastPlayerOver` on every existing ZapZap, Rami and 6 qui prend, so almost every analysis of
those games sends a rule that contradicts how the game ended, and the survivor, who never went
over, reads as someone the rule did not reach.

**Fix:** reword both strings to "every player but one" (the wording of
`gameRulesEndLastOver`), and update the matching test in `backend/tests/`.

**Acceptance:**
- `_GAME_OVER["lastPlayerOver"]` and `["lastPlayerUnder"]` say the game ends when all but one
  player are past the threshold; a pytest asserts the rendered line for `lastPlayerOver`/100.
- No other key in `_GAME_OVER` changes.
