# The in-game Ranking screen ignores the refreshed theme and the player colours

- **Noted:** 2026-09-19 — reported by the user after the end screen (#123) landed
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

The board's leaderboard button (`game_board_screen.dart:241-250`) opens
`lib/screens/ranking_screen.dart`, which predates the refresh
([capture](../assets/2026-09-19-game-ranking-ignores-the-new-theme/today.png)). It shows a full-width teal banner for the win rule,
numbered badges in the scheme's primary colour, an amber trophy tile for the leader, and no
player colour at all (`ranking_screen.dart:46-122`).

Since #123, `lib/screens/game_end_screen.dart` draws the same information in the new style:
podium, player colours, avatars. So a game now has two rankings in two styles. Which one you
see depends on whether the game is finished.

**Fix:** one ranking component, used by both. `RankingScreen` reuses the end screen's podium
and ranked rows (extracted into a widget if they are not one already), with:
- the player colours from `player_colors.dart`;
- the leader's crown as on the board;
- totals within 20 points of the elimination threshold in orange, eliminated players marked out;
- "Play again" kept where it is today (`ranking_screen.dart:152`).

A full-width banner is not used: the win rule becomes a single line under the title.

**Acceptance:**
- `ranking_screen.dart` no longer references `Colors.amber` or `primaryContainer`, and the
  ranking and end screens build their rows from the same widget.
- A widget test on an open game: the ranking shows each player in their board colour, with
  the crown on the leader.
- A widget test on a lowest-wins and a highest-wins game: ranks match the end screen's.
