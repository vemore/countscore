# A game-type rule change is not checked against the open game until the next round

- **Noted:** 2026-09-24 — independent review of #213 (fix/game-ends-on-last-player), point 6
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

The board runs its game-over check when the open game's totals or finished state change
(`_checkGameOverOnTotals`, `lib/screens/game_board_screen.dart`), after its own writes, and
when it opens. A change to the **rule** that leaves the totals alone is not one of those:

- *Edit game* on the board switches the game to another type (`GameProvider.updateGameType`);
- the game-type editor changes the threshold or the condition of the type in use;
- a pull brings a `game_types` row with a new condition (`GameTypeProvider` reloads, the
  `GameProvider` does not notify a totals change).

A game that the new rule already ends stays open until the next round is typed, or the
board is opened again. Not a regression: before #213 the check waited for a board write too.

**Fix:** also listen to `GameTypeProvider` on the board, and run `_maybeShowGameOver` when the
open game's type (id, condition, threshold, elimination) changes; or include those fields in
the key `_checkGameOverOnTotals` compares.

**Acceptance:**
- Widget test: a ZapZap board with one player left and no end condition; setting
  `lastPlayerOver`/100 on the type through `GameTypeProvider` ends the game and opens the end
  screen without a new round.
- Widget test: switching the open game to a type whose rule it already meets does the same.
- A rule change that the game does not meet opens nothing.
