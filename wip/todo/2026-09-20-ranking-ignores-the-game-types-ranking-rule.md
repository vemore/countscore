# The ranking is always the score order, whatever the game type's rule, and does not tell the live standings from the final result

- **Noted:** 2026-09-20 — reported by the user, reproduced on the PWA built from `main`
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

`GameStanding.ranks` (`lib/models/game_standing.dart:52`) knows one rule: count how many
players have a better total under `isLowestScoreWins`. `GameRanking` reads `GameType` only for
`isEliminated` / `isNearElimination`, which are styling — struck-out names, orange totals — and
never for a place. The board's `#n` badges, the ranking screen and the end screen all come out
of that one comparison.

**Reproduced** — ZapZap (out above 100, lowest wins), four players, 5 rounds:
Alice out in round 1 with 101 · Bob out in round 4 with 140 · Chloe out in round 5 with 115 ·
David alone at the end with 50. The app ranks David 1, **Alice 2**, Chloe 3, Bob 4, and puts
Alice — out after one hand — on the podium ahead of the two who played to the end. By
elimination order it is David, Chloe, Bob, Alice.

Three shapes exist in `GameType.defaultGameTypes()` and nothing distinguishes them:

| Shape | Types | What the final order should be |
|---|---|---|
| Elimination | `zapzap`, `rami`, `six_nimmt` (`playerDeadConditionType`) | the survivor first, then the others by **reverse elimination order**; the total only breaks a tie |
| Race to a total | `uno`, `skyjo`, `president`, `belote`, `coinche`, `flip7`, `mille_bornes`, `farkle`, `canasta` (`gameOverConditionType`) | the total, as today |
| No rule | `scrabble`, `other`, `tarot`, `bridge`, `yahtzee`, `phase10`, `rummikub`, `qwirkle`, `wizard`, `triomino` | the total — and for `other`, arguably no place at all, only totals |

**And the live standings are not the final result.** While the game runs, the score order is
the right thing to show for every shape. Only at the end does the elimination order take over.
The two screens show the same thing today
([[2026-09-20-ranking-and-end-screen-are-the-same-screen]]).

**Also found:** an elimination type has no game-over rule at all — `_checkGameOverCondition`
(`lib/screens/game_board_screen.dart:525`) returns false without a `gameOverConditionType`, so
a ZapZap game with one player left still offers "Round 6" and never ends by itself. The rules
screen says as much: "No automatic end: you decide when the game is over."

**Fix:** give `GameType` a ranking rule beside its elimination rule, and have `GameStanding`
take it plus the rounds. Elimination order needs no schema change: it is the first round whose
running total crosses `playerDeadThreshold`, derivable from the stored scores. Add a
`lastSurvivor` game-over condition so an elimination game ends on its own.

**Acceptance:**
- In the reproduction above the final order is David, Chloe, Bob, Alice, on the board badges and on the standings screen.
- While the game is open the same game still ranks by total.
- A race-to-a-total type and a type with no rule rank exactly as they do today (regression test).
- A ZapZap game with one player left offers to end, as a threshold game does.

**Decided (2026-09-20, the user):** a type with no rule ranks **by score**, which is the
default the ranking rule falls back to — `other` included. Only a type that carries a rule of
its own departs from it, and today that is the elimination shape alone.

**Open question:** should the elimination order be *shown* — an "out in round 4" line under a
player — or only used to sort? The order itself is settled either way.
