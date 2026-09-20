# The podium hides the first three from the list, so the standings cannot be read top to bottom

- **Noted:** 2026-09-20 — reported by the user, reproduced on the PWA built from `main` (412×860)
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

`RankedPlayers` (`lib/widgets/game_ranking.dart`) splits the ranking in two: `ranked.take(3)`
goes into the `_Podium`, `ranked.skip(3)` into the `_RankRow` list. With four players the list
below the podium starts at "4 Bob 140" — to read the order the eye has to decode the podium's
2-1-3 block layout first, then jump back to the list.

**Fix:** keep the podium, and put **every** player in the list under it, first to last — the
top three appear twice on purpose, once as the picture and once as the first three rows.
`_RankRow` already renders a place, a colour, a name and a total, so this is
`for (final player in ranking.ranked)` instead of `ranking.ranked.skip(3)` plus whatever
emphasis the first row deserves.

**Acceptance:**
- The list under the podium starts at place 1 and ends at the last player, for 2, 3, 4 and 8 players.
- A tie still shares a place in the list as it does on the podium (1, 1, 3).
- The screen does not scroll at 412×860 for four players.
