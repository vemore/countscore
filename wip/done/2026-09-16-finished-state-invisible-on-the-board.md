# Nothing on a finished game's board says it is finished, and finishing it says nothing either

**Status:** done (2026-09-16) — closed by fix/end-of-game-polish. The board's app bar
carries a `l10n.gameFinished` chip beside the title whenever `finishedAt` is set, and both
triggers — the game list's menu and the board's — now confirm with a snackbar whose **Undo**
action writes the previous state back (the repo's first `SnackBarAction`; messenger captured
before the await, as in `players_screen.dart`). **Add round** is deliberately left enabled:
`GameProvider.setGameFinished` documents that a finished game still takes rounds and score
edits. Pinned by `test/screens/game_board_end_of_game_test.dart`.

- **Noted:** 2026-09-16 — testing `feat/explicit-end-of-game` on the Pixel 9 Pro XL
- **Theme:** growth
- **Area:** app
- **Blocks release:** no

`games.finishedAt` has exactly one visible consequence: a 16 px `Icons.flag` next to the
title in the game list (`lib/screens/home_screen.dart:385`). Two gaps behind it, both seen
on device:

- **The board shows nothing.** Opening a finished game gives the same app bar, the same
  table and the same full-width **Ajouter un tour** as an open one; the only clue is opening
  the overflow menu and reading **Rouvrir la partie**. The list and the board disagree about
  a fact the list is willing to display.
- **Finishing is silent.** `_handleGameAction` (`lib/screens/home_screen.dart:510`) and the
  board's `finish_game` branch both write and return with no snackbar. On the home screen the
  whole feedback is a small icon appearing in a row the user's finger is covering; on the
  board there is no feedback at all. There is also no undo, though the action is reversible.

The badge itself is fine: purple on the beige card in light mode, light purple on the dark
card in dark mode, legible in both, and it mirrors correctly in Arabic.

**Fix:** show the state where the game is, and confirm the action. A chip or a struck-through
"Terminée" line under the app bar title on the board — `l10n.gameFinished` already exists in
all ten languages — and a snackbar on both triggers, with an **Annuler** action calling
`setGameFinished(id, !finished)`.
