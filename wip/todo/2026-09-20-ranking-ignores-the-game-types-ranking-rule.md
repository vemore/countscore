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

**Also found, split out:** an elimination type has no game-over rule at all —
`_checkGameOverCondition` (`lib/screens/game_board_screen.dart:525`) returns false without a
`gameOverConditionType`, so a ZapZap game with one player left still offers "Round 6". That is
its own entry:
[[2026-09-20-the-last-player-standing-condition-is-mislabelled-misimplemented-and-unset]].

**Fix:** give `GameType` a ranking rule beside its elimination rule, and have `GameStanding`
take it plus the rounds. Elimination order needs no schema change: it is the first round whose
running total crosses `playerDeadThreshold`, derivable from the stored scores. The game-over
rule an elimination type is missing is not a new one —
[[2026-09-20-the-last-player-standing-condition-is-mislabelled-misimplemented-and-unset]] fixes
and seeds the `lastPlayerOver` condition that already means it.

**Acceptance:**
- In the reproduction above the final order is David, Chloe, Bob, Alice, on the board badges and on the standings screen.
- While the game is open the same game still ranks by total.
- A race-to-a-total type and a type with no rule rank exactly as they do today (regression test).

**Decided (2026-09-20, the user):** a type with no rule ranks **by score**, which is the
default the ranking rule falls back to — `other` included. Only a type that carries a rule of
its own departs from it, and today that is the elimination shape alone.

**Decided (2026-09-20, the user):** the elimination order applies only to a type that has an
elimination threshold **and** whose win condition is "last player standing". Anything else —
including a type with a threshold but a race-to-a-total ending — ranks by score. That makes
[[2026-09-20-the-last-player-standing-condition-is-mislabelled-misimplemented-and-unset]] a
prerequisite: no type can express that win condition today.
