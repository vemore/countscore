# `lastPlayerUnder` is last player standing too, but does not rank by the elimination order

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

**Open question:** does the user want the `under` shape to follow the elimination order too?
The 2026-09-20 decision only named the `over` one.
