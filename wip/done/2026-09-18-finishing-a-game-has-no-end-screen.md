# Finishing a game shows a dialog or a snackbar, never who won

**Status:** done (2026-09-19) — closed by `feat/game-end-screen`. `lib/screens/game_end_screen.dart` replaces the game-over dialog (the rule finishes the game and opens it, "Continue playing" reopens it) and the home snackbar, and a finished game's board reopens it from a trophy in the app bar; tests in `test/screens/game_end_screen_test.dart` and `test/screens/game_board_end_of_game_test.dart`.

- **Noted:** 2026-09-18 — visual refresh, split into one pull request per screen
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

Part of the visual refresh, direction A "Material soigné", chosen from four mock-up directions
(split out of `wip/done/2026-09-18-app-looks-like-a-default-material-template.md`). The images
in [`wip/assets/…material-template/`](../assets/2026-09-18-app-looks-like-a-default-material-template/) are the target (light, and `dark-` prefixed); the
interactive page is https://claude.ai/artifact/D3ycxcgzPxHezRrSrmuxiw (private).

**Target:** [end of game](../assets/2026-09-18-app-looks-like-a-default-material-template/end-of-game.png), [dark](../assets/2026-09-18-app-looks-like-a-default-material-template/dark-end-of-game.png).

A game-over condition opens an `AlertDialog` offering "continue" or "finish"
(`_maybeShowGameOver` and `_showGameOverDialog`, `game_board_screen.dart:578` and `837`). Finishing from the home menu shows a snackbar
(`home_screen.dart:776-793`). Neither one names the winner.

Lands after [[2026-09-18-board-hides-who-owns-each-column-and-who-leads]] (merged in #119): same
screen, same ranking logic (`GameStanding`). Built in parallel with
[[2026-09-18-score-entry-takes-a-dialog-per-cell]]: same screen, expect a merge conflict.

**Fix:** a **game-end screen** (`lib/screens/`), shown **always**:
- it replaces the game-over dialog when the rule ends the game (a "Continue playing" action
  keeps today's way out, needed for golden score);
- it opens when "End game" is chosen on the board or on home;
- it is reachable again from a finished game (the board's app bar).

The screen shows the winner's name, the game type and number of rounds, a podium of the top 3
in their colours with their totals, then the other players in rank order. Actions:
- **"Play again"**, which reuses `lib/utils/play_again.dart`;
- **"Analysis"**, which opens `game_analysis_screen.dart`, **hidden when no server is
  configured** (`BackendProvider.isConfigured`), in which case "Play again" spans the whole
  width.

The review prompt still fires once per game that has just been finished
(`ReviewPromptService.onGameFinished`).

**Acceptance:**
- Widget test: reaching the game-over condition opens the end screen with the right winner
  for both a lowest-wins and a highest-wins type, and "Continue playing" returns to the board
  with the game still open.
- Widget test: "End game" from home opens the end screen.
- Widget test: "Play again" creates the next game with the same players.
- Widget test: "Analysis" is absent when `isConfigured` is false and present when it is true.
