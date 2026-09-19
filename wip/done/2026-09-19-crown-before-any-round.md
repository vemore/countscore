# The Ranking screen crowns a leader in a game with no round played

**Status:** done (2026-09-19) — closed by fix/elimination-and-crown. The rankings crown `GameStanding.soleLeader`, null before a score and on a tie for the lead; each podium step is as high as the player's place, so tied players share a step. Tested in `test/screens/ranking_screen_test.dart` (no round, a round of zeros, a tie) on both the Ranking and the end screen. The board's crown and the home card's winner still break a tie by seat: `wip/todo_nr/2026-09-19-board-and-home-crown-a-tie.md`.

- **Noted:** 2026-09-19 — smoke-testing the in-game Ranking after #131, on the production PWA
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

On a ZapZap game whose summary line reads "ZapZap · 0 rounds · lowest score wins", with both
players on 0, the Ranking screen puts Al on the top step with the gold crown and Bo second.
`GameRanking.leader` (`lib/widgets/game_ranking.dart:88-89`) is documented as "null before the
first score". So either the game holds an empty or all-zero round that the round count does
not show, or the leader is picked from a tie at 0 by seat order.

**Changed (2026-09-19, refinement):** the no-round case is already right — `GameRanking.of` builds
empty totals and `GameStanding.leader` returns null while `!hasScores`
(`lib/models/game_standing.dart:24-29`). The tie case is still wrong: `leader` documents "A
tie goes to the earlier seat" (:27) and picks it (:30-39), so a round of all zeros crowns
seat 1.

**Fix:** reproduce with a widget test (no round, and one round of all zeros), then: a tie for the lead gives no
crown and a shared first place, as the ranked rows already do for ties.

**Acceptance:**
- A widget test on a game with no round shows no crown on the Ranking and end screens (a
  regression test; it passes today).
- A widget test on one round of all zeros shows no crown.
- A widget test on a tie shows both tied players with the same place.
