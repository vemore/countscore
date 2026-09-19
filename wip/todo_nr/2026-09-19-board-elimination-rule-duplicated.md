# The board still carries its own copy of the elimination rule

- **Noted:** 2026-09-19 — while moving the in-game ranking onto the end screen's widget (feat/ranking-restyle)
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

The elimination rule on a total — out past `playerDeadThreshold`, orange within 20 points
of it — now lives in `lib/widgets/game_ranking.dart` (`isEliminatedBy`,
`isNearEliminationBy`), which the ranking and end screens use. `game_board_screen.dart`
keeps three copies of its own: the local `isPlayerEliminated` and `isNearThreshold` in
`build`, and `_isPlayerEliminatedByTotal`. The board was out of bounds for that pull request
(another branch was editing it), so a change to the rule today has to be made in two places,
and the ranking and the board could disagree on who is out.

**Fix:** the board calls `isEliminatedBy` / `isNearEliminationBy` (moved to `lib/utils/` or
onto `GameType` if that reads better) and its three local copies go.

**Acceptance:**
- `game_board_screen.dart` no longer compares a total with `playerDeadThreshold` itself.
- The existing board and end-of-game tests stay green.
