# `lastPlayerUnder` is last player standing too, but does not rank by the elimination order

**Status:** done (2026-09-20) — closed by `feat/elimination-ranking-model`.
`GameStanding.ranksByEliminationOrder` now switches on the game-over condition and takes
`lastPlayerOver` **and** `lastPlayerUnder`, the two conditions `GameType.isGameOver` already
treats as one shape; a `lastPlayerUnder` type with no elimination threshold, and
`firstPlayerUnder`, still rank by the total. `test/models/game_standing_test.dart` mirrors
the `over` reproduction round for round and place for place, and pins the twenty-two seeded
types to the three that depart from the score order (`zapzap`, `rami`, `six_nimmt`) — none
of them `lastPlayerUnder`, so no existing standing moved.

- **Noted:** 2026-09-20 — while implementing the ranking rule (`feat/ranking-rule`)
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

`GameStanding.ranksByEliminationOrder` (`lib/models/game_standing.dart`) tests
`gameOverConditionType == GameOverConditionType.lastPlayerOver` exactly, as the user's
decision of 2026-09-20 words it
(`wip/done/2026-09-20-ranking-ignores-the-game-types-ranking-rule.md`). But `GameType`
itself documents **two** last-player-standing conditions: "`lastPlayerOver` and
`lastPlayerUnder` are last player standing" (`lib/models/game_type.dart:isGameOver`), and
`GameType.isEliminated` already carries the direction in `playerDeadConditionType`.

So a type with `playerDeadConditionType: under` and `gameOverConditionType: lastPlayerUnder`
— a game you are out of once you fall below a floor, ending when one player is left — ranks
by the total, though it is the same shape the rule was written for. No seeded type uses it
(`zapzap`, `rami`, `six_nimmt` are all `lastPlayerOver`), so only a type the user builds can
hit it, and nothing is wrong today.

**Fix:** either widen the predicate to both `lastPlayerOver` and `lastPlayerUnder` — one
`switch` in `ranksByEliminationOrder`, plus a test mirroring the `over` one — or keep it
narrow and say so in the game-type editor, so a user who picks `lastPlayerUnder` is not
surprised.

**Decided (2026-09-20, refinement):** widen it to both. "Last player standing" means what it
says whichever direction the threshold runs, so `ranksByEliminationOrder` takes
`lastPlayerOver` **and** `lastPlayerUnder`. The narrow alternative — keeping the predicate as
it is and warning in the game-type editor — was rejected: it would ask the user to understand
a distinction the model itself does not make (`GameType.isGameOver` already documents the two
as one shape, and `isEliminated` already carries the direction in `playerDeadConditionType`).

**Acceptance:**
- `ranksByEliminationOrder` is true for a finished game of a type whose `gameOverConditionType`
  is `lastPlayerUnder` and whose `playerDeadConditionType` is set, and a test mirrors the
  existing `over` case in `test/models/game_standing_test.dart`.
- A type with `lastPlayerUnder` and **no** elimination threshold still ranks by the total.
- The twenty seeded types keep exactly the places they have today (no seeded type is
  `lastPlayerUnder`, so the existing standings tests must not move).
