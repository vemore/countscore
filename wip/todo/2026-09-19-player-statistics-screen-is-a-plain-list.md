# Player statistics are a list of collapsed tiles that says little and looks unrelated to the app

- **Noted:** 2026-09-19 — reported by the user; needs design exploration with mock-ups
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

`lib/screens/player_stats_screen.dart` shows one `ExpansionTile` per player, with "N games"
as the only thing visible collapsed. Expanded, it shows three counters (games, wins, win rate)
and a grey per-game-type box ([capture](../assets/2026-09-19-player-statistics-screen-is-a-plain-list/today.png)). Found on the way:
- **Avatar colours disagree with the board.** They come from the stored `colorValue`, with
  `Colors.blue` as the fallback (`player_stats_screen.dart:68-70` and `:104-107`), not from
  `player_colors.dart`. Lionel and Laurent both show a cyan "L": two players who look alike,
  whom the board tells apart.
- **One initial**, where the rest of the app now uses two letters (`player_avatars.dart`).
- **Nothing visual:** no ranking between players, no trend, no chart. There are no head-to-head
  records, no streaks and no best or worst game, even though the data exists (`game_players`,
  scores per round).

The user wants several design trials before deciding.

**Decided (2026-09-19):** from the four directions drawn
(https://claude.ai/artifact/MWw9hSctjPCW6XwXKrvJXd, boards "Stats 1–4"), the user chose
**1, the leaderboard**, with **2, the player card**, opened by tapping a player's name.
Everything on both screens is scoped to the game type selected on the leaderboard. Target
images: [leaderboard](../assets/2026-09-19-player-statistics-screen-is-a-plain-list/target-leaderboard.png),
[player card](../assets/2026-09-19-player-statistics-screen-is-a-plain-list/target-player-card.png).

**Fix:**
- **Leaderboard** (replaces the `ExpansionTile` list): a row of game-type filter chips
  ("All games" plus the types that have finished games, most played first); a teal hero for
  the best win rate; one card per player with rank, two-letter avatar in the
  `player_colors.dart` colour, games, wins and win rate, and a win-rate bar in the player's
  colour. Players below 5 finished games of the filter are listed last, unranked.
- **Player card** (new screen), for the filter chosen on the leaderboard: a strip of the other
  players' avatars to switch player; games, wins and average final rank; the final rank over
  the last 12 games as a line chart with wins marked in gold; the current win streak and the
  best final total (following `isLowestScoreWins`); then average final total, best final total
  and the opponent most often finished ahead of.
- The avatar colour and two-letter fixes above.
- All figures come from finished games, keyed by player UUID; no schema change.

**Acceptance:**
- `player_stats_screen.dart` no longer uses `ExpansionTile` or `Colors.blue`; avatars come from
  `player_colors.dart` and `player_avatars.dart` (widget test: same colour as on the board).
- A widget test selects a game-type chip, and the ranks and win counts change to that type.
- A widget test taps a player: the card opens scoped to the selected type, and its average
  rank, streak and best total match a seeded fixture (lowest-wins and highest-wins cases).
- The two screens match the target images at 412 dp wide (layout, not exact pixels).
