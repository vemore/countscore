# 6 qui prend eliminates a player one point later than its rule says

**Status:** done (2026-09-19) — closed by fix/elimination-and-crown. The board's three copies of the elimination test are gone: board, ranking and end screen call `GameType.isEliminated` / `isNearElimination`. `GameType.sixNimmt()` seeds 65 (new databases only; an existing row keeps 66), and the ten `six_nimmt` rules texts say a player is out on reaching 66. Tested in `test/drift/six_nimmt_seed_test.dart` and `test/models_test.dart`.

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

**Fix:** first remove the board's own copies of the rule — the local `isPlayerEliminated` and
`isNearThreshold` in `build` and `_isPlayerEliminatedByTotal`
(`game_board_screen.dart:450-476`, `:536-545`) — so the board calls `isEliminatedBy` /
`isNearEliminationBy` (`lib/widgets/game_ranking.dart:102-121`, moved to `lib/utils/` or onto
`GameType` if that reads better); absorbed from
[[2026-09-19-board-elimination-rule-duplicated]]. Then seed 6 qui prend with 65 (new
databases only, like the Uno/Président seed change) and drop the "set it to 65" sentence
from the ten rules texts.

**Decided (2026-09-19, refinement):** seed 65. No inclusive elimination variant, no schema change.

**Acceptance:**
- A fresh database eliminates a 6 qui prend player on exactly 66, and not on 65.
- `game_board_screen.dart` no longer compares a total with `playerDeadThreshold` itself; the
  existing board and end-of-game tests stay green.
- The `six_nimmt` section of the ten `assets/rules/rules_<locale>.md` files matches.
