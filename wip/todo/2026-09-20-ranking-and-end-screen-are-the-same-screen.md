# Ranking and the end screen are the same screen, reached by two buttons

- **Noted:** 2026-09-20 — reported by the user, reproduced on the PWA built from `main` (412×860)
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

`lib/screens/ranking_screen.dart` and `lib/screens/game_end_screen.dart` both render the same
`RankedPlayers(ranking: GameRanking.of(...))` under the same `rankingSummary` line, with the
same `ShareResultButton` and the same *Play again*. What differs is a headline
(`game_end_headline`, "David wins") on the end screen and, when a server is configured, its
*Analysis* button.

On a **finished** game the board's app bar therefore carries two adjacent icon buttons that
open two near-identical screens: the trophy (`board_game_end`, `Icons.emoji_events_outlined`,
`l10n.gameEndResults`, `game_board_screen.dart:236`) and the leaderboard
(`Icons.leaderboard`, `l10n.ranking`, `game_board_screen.dart:245`).

**Fix:** one screen. The leaderboard button is the only one the board needs; whether the game
is finished decides what it shows — headline and *Analysis* when it is, the live standings
when it is not. Drop the trophy button, drop the second screen, and keep a single route the
board, the home list and `_openGameEnd` all push. See also
[[2026-09-20-ranking-ignores-the-game-types-ranking-rule]], which splits *what* the two states
must show.

**Acceptance:**
- A finished game's board app bar has exactly one button that leads to the standings.
- That screen shows the winner headline and *Analysis* on a finished game, and neither on an open one.
- No widget test still references two separate screens for the same game.
