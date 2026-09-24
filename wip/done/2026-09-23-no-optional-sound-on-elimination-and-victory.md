# No optional sound on elimination and victory

**Status:** done (2026-09-24) — closed by feat/board-skull-sounds-timer. Settings → Sounds → *Game sounds* (off by default) governs `GameSounds` (`lib/services/game_sounds.dart`, audioplayers 6.8.1, MIT), which plays the elimination sound once per write that puts a player out and the victory sound when the rule ends the game; the unconditional `SystemSound` alert is gone. The sounds are synthesised by `scripts/generate_sounds.py`, CC0, recorded in `THIRD_PARTY_LICENSES.md` (no credit needed). Tested in `test/screens/game_board_sounds_test.dart`, `test/services/game_sounds_test.dart` and `test/screens/settings_screen_test.dart`.

- **Noted:** 2026-09-23 — user request
- **Theme:** growth
- **Area:** app
- **Blocks release:** no

The user wants the board to play a "death" sound when a player is eliminated and a victory
sound when a game is won. The sound is set in Settings and is **off by default**.

Today an elimination already plays an unconditional `SystemSound.play(SystemSoundType.alert)`
(`lib/screens/game_board_screen.dart:894-909`, `_noteEliminations`). It can't be turned off
and does nothing on most Android devices and on the web. Victory has no sound:
`_maybeShowGameOver` (`game_board_screen.dart:525`) only opens the end screen.

**Fix:**
- A "Game sounds" switch in Settings, persisted in `SharedPreferences`, default off. When
  off, the existing `SystemSound` alert goes away too, so the default is silence.
- Two short bundled assets (death, victory) under a licence we can ship (CC0), credited in
  the About screen if the licence asks. Played through one audio package (e.g.
  `audioplayers`, through the dependency review) that works on Android and on the web. On
  the web a sound needs a prior user gesture, and a score entry counts as one.
- Elimination: played once per newly eliminated player (the existing `_eliminatedPlayers`
  set). Victory: played when the end screen opens by rule, not when an already finished
  game is reopened.
- Shares the setting and the player with the turn-timer sound
  ([[2026-09-18-no-turn-timer-on-the-board]]), whichever lands first builds them.

**Acceptance:**
- Widget test with a fake sound service: nothing plays with the setting off (the default), including on elimination.
- With the setting on, one elimination plays the death sound once; a correction that brings the player back and out again plays it again.
- With the setting on, reaching the end condition plays the victory sound once; reopening a finished game does not.
- The setting label exists in the ten ARB files; the assets' licence is recorded.
