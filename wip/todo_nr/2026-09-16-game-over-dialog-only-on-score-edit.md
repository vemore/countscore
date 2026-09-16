# The game-over dialog fires only when a score is edited, never when a round is added

- **Noted:** 2026-09-16 — while adding the explicit end of a game (feat/explicit-end-of-game)
- **Theme:** growth
- **Area:** app
- **Blocks release:** no

`_checkGameOverCondition` (`lib/screens/game_board_screen.dart:463`) has exactly one call
site: `handleScoreUpdate`, a closure inside `_showScoreDialog` (same file, l. 796). Nothing
checks the condition when a round is added (`board_add_round`, l. 427), when a round is
deleted, or when the board is opened.

So even for the three types that define a threshold — Skyjo, Président, Belote — a game can
sit past its game-over condition with no dialog, as long as the crossing score was not the
last cell the user touched. Reopening the board does not notice either.

This is much less severe since `feat/explicit-end-of-game`: every game can now be ended from
the board menu or the game list, so the dialog is one trigger among several rather than the
only one. It is still a condition the app claims to detect and does not.

**Fix:** call `_checkGameOverCondition` after `addRound` and on the board's first build for a
game that already has rounds, not only from `handleScoreUpdate`. Guard against re-showing it
for a game the user already answered "Continue playing" on — which today is not recorded
anywhere, and is the reason the check was left on the one path that has a natural moment.
