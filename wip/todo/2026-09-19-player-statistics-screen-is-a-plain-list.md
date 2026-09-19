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

**Fix, in two steps:**
1. **Explore** (no code): a mock-up page in the style of the refresh with 3 or 4 directions.
   For example a leaderboard of players across games; a player card with trends
   (wins over time, average rank); head-to-head; per-game-type records. Each is checked
   against the data the schema actually holds (`.llmwiki/SchemaV10.md`, stats keyed by player
   UUID since v9). The user picks; the target images land in `wip/assets/2026-09-19-player-statistics-screen-is-a-plain-list/`.
2. **Implement** the chosen direction, with the colour and avatar fixes above folded in.
   Split into several entries if it outgrows one pull request.

**Acceptance (step 1):**
- A mock-up page with at least 3 directions is published, and its link is recorded here.
- The chosen direction's target images are committed under `wip/assets/2026-09-19-player-statistics-screen-is-a-plain-list/`, and this entry
  is rewritten with the implementation fix and acceptance.

**Open question:** which direction, decided from the mock-ups.
