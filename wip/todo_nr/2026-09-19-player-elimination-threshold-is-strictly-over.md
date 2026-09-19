# 6 qui prend eliminates a player one point later than its rule says

- **Noted:** 2026-09-19 — writing the long-tail rulesets in feat/game-rules-twelve
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

`PlayerDeadConditionType.over` is strict: `_isPlayerEliminatedByTotal` in
`lib/screens/game_board_screen.dart` marks a player out when `total > playerDeadThreshold`.
That is right for ZapZap and Rami, whose rules say "eliminated once a total **exceeds** 100".
It is not right for 6 qui prend (seeded `over` 66, `GameType.sixNimmt()`): the box rule ends
the game as soon as a player **has** 66 bull heads. The shipped text says so and tells the
user to set 65 in the game type to follow it to the letter — a workaround, not a fix.

The game-over condition had the same mismatch and became `>=` on 2026-09-19
(`wip/done/2026-09-18-game-over-threshold-is-strictly-over.md`); elimination was left
alone because ZapZap and Rami need the strict reading.

**Fix:** either seed 6 qui prend with 65 (new databases only, like the Uno/Président seed
change) and drop the sentence from the ten rules texts, or give the elimination rule an
inclusive variant. The first is one line and no schema change.

**Acceptance:**
- A fresh database eliminates a 6 qui prend player on exactly 66, and not on 65.
- The `six_nimmt` section of the ten `assets/rules/rules_<locale>.md` files matches.
