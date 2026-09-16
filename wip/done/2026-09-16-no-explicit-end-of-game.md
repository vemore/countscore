# Only three game types can ever declare a game over

**Status:** done (2026-09-16) — closed by `feat/explicit-end-of-game`. `games.finishedAt`
(schema v12, synced as the server's existing `ended_at`) plus a "Terminer la partie" /
"Rouvrir la partie" action on the board menu and on the home-screen game menu, a finished
badge in the game list, and the game-over dialog now persisting what it announces. All four
triggers go through `GameProvider.setGameFinished`, which reports the null → set transition
so `ReviewPromptService.onGameFinished` fires for every game type instead of three.

- **Noted:** 2026-09-16 — while wiring the review prompt to the end of a game (feat/rating-prompt)
- **Theme:** growth
- **Area:** app
- **Blocks release:** no

The "Partie terminée" dialog in `lib/screens/game_board_screen.dart:720` is the app's only
statement that a game is finished, and `_checkGameOverCondition` (same file, l. 460) shows it
only when the game type carries both `gameOverConditionType` and `gameOverThreshold`. In
`lib/models/game_type.dart` `defaultGameTypes()` that is **3 of the 10 defaults** — Skyjo,
Président, Belote. ZapZap (the flagship, and the only type with an LLM analysis), Uno,
Scrabble, Tarot, Bridge, Rami and "Autre" define no condition, so those games simply stop
being opened.

Consequences: `GameProvider` has no notion of a finished game, the game list cannot
distinguish a finished game from an abandoned one, and — added by feat/rating-prompt —
`ReviewPromptService.onGameFinished` is only ever called for those three types, so most users
can never reach the Play review sheet. That is the weakest link in the zero-reviews fix.

**Fix:** give every game an explicit end. Either a "Finish game" entry in the board's overflow
menu (and in the home-screen game menu) that records the moment, or a persisted
`finishedAt` on `games` (`db-migration` skill, schema bump, sync field) with the board
offering it whenever a game has at least one round. `_showGameOverDialog` then becomes one
trigger among several rather than the only one, and the review prompt, the game list and any
future "finished games" statistic all read the same fact.
