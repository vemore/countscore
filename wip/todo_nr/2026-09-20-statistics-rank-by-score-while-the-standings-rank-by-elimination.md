# The statistics rank a finished elimination game by the total, while its standings rank it by the elimination order

- **Noted:** 2026-09-20 — while implementing the ranking rule (`feat/ranking-rule`)
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

Since `feat/ranking-rule`, a finished game of a type that puts a player out on a threshold
**and** ends on the last player standing (`zapzap`, `rami`, `six_nimmt`) ranks by the
elimination order on the board, on the standings screen, in the shared text and on the home
card (`GameStanding.forGame`, `lib/models/game_standing.dart`).

The statistics do not. `FinishedGameResult._computeRanks`
(`lib/models/player_stats.dart:71-86`) still counts better totals, because
`PlayerStatsRepository.getFinishedGameResults` hands it totals only — no rounds, no scores —
and the elimination order is derived from the rounds. So for the same finished ZapZap game
the standings say David 1, Chloé 2, Bob 3, Alice 4 while the player card, the leaderboard,
the win count, the average place and the rank chart say David 1, Alice 2, Chloé 3, Bob 4:
Alice is credited with a podium she did not earn.

**Fix:** carry what the rule needs into the statistics. Either
`getFinishedGameResults` returns each participant's elimination round (one more query over
`scores`/`rounds`, the same walk `GameStanding.forGame` does), or `FinishedGameResult` is
built from a `GameStanding` and the type. The type's conditions are needed too, which
`FinishedGameResult` does not carry today — only `gameTypeKey` and `isLowestScoreWins`.

**Acceptance:**
- A finished ZapZap game gives the same places in the player card as on its standings screen.
- A race-to-a-total game and a game with no type keep exactly the places they have today.
