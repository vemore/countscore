# The Ranking screen crowns a leader in a game with no round played

- **Noted:** 2026-09-19 — smoke-testing the in-game Ranking after #131, on the production PWA
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

On a ZapZap game whose summary line reads "ZapZap · 0 rounds · lowest score wins", with both
players on 0, the Ranking screen puts Al on the top step with the gold crown and Bo second.
`GameRanking.leader` (`lib/widgets/game_ranking.dart:88-89`) is documented as "null before the
first score". So either the game holds an empty or all-zero round that the round count does
not show, or the leader is picked from a tie at 0 by seat order.

**Fix:** reproduce with a widget test (no round, and one round of all zeros), then: no crown
and no podium order while no round has been validated, and a shared first place on a real
tie, as the ranked rows already do for ties.

**Acceptance:**
- A widget test on a game with no round shows no crown on the Ranking and end screens.
- A widget test on a tie shows both tied players with the same place.
