# Player statistics count open and empty games, and call whoever leads right now a winner

**Status:** dropped (2026-09-19) — merged into [[2026-09-19-players-screen-counts-open-games-and-shows-blue-avatars]]. #137 (5579bab) moved Statistics to `getFinishedGameResults`; what is left — `getStatsByName` on the Players screen, its win rule and its N + 1 query — is the survivor's problem.

- **Noted:** 2026-09-19 — full test pass of the production PWA (fresh Chromium profiles, Playwright, fr-FR at 412 × 860)
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

`getPlayerStats` (`lib/repositories/drift/drift_repositories.dart:712-770`) counts
**every** live game a player is in. It then counts a "win" whenever the player's current
total equals the best total. The game does not need to be finished, and nobody needs to have
played a round.

Seen on the PWA ([capture](../assets/2026-09-19-player-stats-count-open-games-as-wins/players-screen.png)), with one reopened game in progress and
one "play again" game with no rounds: every player shows "2 parties". Thibaut has
"2 victoires" (he leads the open game, and ties at 0 in the empty one). Lionel, Laurent and
Vincent each have "1 victoire", from nothing but the 0-0-0-0 tie. The same numbers feed the
Players screen and Statistics.

Also:
- elimination is ignored: a ZapZap winner is decided by the game's rules, while this counts
  the lowest total, which the end screen (#123) may not agree with;
- the query runs one extra `SELECT` per game (N + 1).

**Fix:** count only finished games (`finishedAt IS NOT NULL`) with at least one round, and
take the winner from the same ranking the end screen uses, shared rather than recomputed.
Report "in progress" separately if wanted.

**Acceptance:**
- A repository test: a finished game counts as played, with the win going to the end
  screen's winner; an open game and an empty game count for nothing.
- A repository test: a tie in a finished game follows the end screen's rule, whatever it is.
- The stats query is one or two statements, not one per game.

Related: [[2026-09-19-player-statistics-screen-is-a-plain-list]] (the redesign) has to show
these numbers.
