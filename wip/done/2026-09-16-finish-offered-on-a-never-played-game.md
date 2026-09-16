# The home-screen menu ends a game that has no round, and it counts towards the review sheet

**Status:** done (2026-09-16) — closed by fix/end-of-game-polish. The home card gates
`finish_game` on `game.isFinished || roundCount > 0`, the board's rule word for word. The
count comes from `RoundRepository.countByGame()`, one grouped `COUNT(*)` folded into
`GameProvider.loadGames()` and kept in step by `addRound`/`deleteRound` — not a
`FutureBuilder` per card, which would be one query per row of the whole history. Pinned by
`test/screens/home_screen_finish_menu_test.dart`.

- **Noted:** 2026-09-16 — testing `feat/explicit-end-of-game` on the Pixel 9 Pro XL
- **Theme:** growth
- **Area:** app
- **Blocks release:** no

The board menu hides **Terminer la partie** until the game has a round — `canFinish` in
`lib/screens/game_board_screen.dart:160`, whose comment states the rule: *"A game with no
round yet was never played, so there is nothing to declare over."* The home-screen game menu
(`lib/screens/home_screen.dart:436`) has no such guard and offers the item unconditionally.

Measured on device: a ZapZap game created with two players and zero rounds could be declared
finished from the home list; `games.finishedAt` was written, the flag badge appeared, and
`reviewPromptGamesFinished` went from 4 to 5. Three taps through three empty games therefore
satisfy the `minGamesFinished` guard in `lib/services/review_prompt.dart` without a single
score being entered — the opposite of the "enough games to have an opinion" the guard is for.

**Fix:** apply the same rule on the home screen. The list item already has the game; add the
round count to what `_buildGameCard` reads (or expose `hasRounds` on the list query) and gate
the `finish_game` item on `game.isFinished || hasRounds`, exactly as the board does.
