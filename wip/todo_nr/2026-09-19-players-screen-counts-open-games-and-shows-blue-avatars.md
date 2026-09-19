# The Players screen counts open games and still draws players in blue

- **Noted:** 2026-09-19 — while replacing the player statistics with the leaderboard (feat/player-stats-leaderboard)
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

`lib/screens/players_screen.dart` still reads `GameProvider.getPlayerStats(name)`, i.e.
`DriftPlayerStatsRepository.getStatsByName`, which counts **every** live game — open ones
included — and makes every player of a game with no score a winner (everyone ties at 0).
The leaderboard and the player card now count only finished games with a score
(`getFinishedGameResults`, `lib/models/player_stats.dart`), so the same player can show
"12 games, 5 wins" under Players and "9 games, 4 wins" under Statistics.

The same screen draws each avatar in the stored `colorValue` with `Colors.blue` as the
fallback (`players_screen.dart:92` and `:183`) and an `Icons.person` glyph, not the
`player_colors.dart` colour and the two-letter `PlayerAvatar` the board, the game list
and now the statistics use.

**Fix:** derive the Players screen's counts from `getFinishedGameResults` (games and wins
per uuid, as `buildLeaderboard(results, kAllGameTypes)` does). The delete confirmation
(`:291`) rightly counts every game the delete touches, open ones too, so it keeps a count of
its own; draw the avatar with
`PlayerAvatar(letters: 2)` in `playerColorsByUuid` — keeping the tap that opens the colour
picker.

**Acceptance:**
- A player with one open and one finished game shows "1 game" on the Players screen, as on
  the leaderboard.
- `players_screen.dart` no longer uses `Colors.blue`; a widget test finds the same avatar
  colour as on the leaderboard.
