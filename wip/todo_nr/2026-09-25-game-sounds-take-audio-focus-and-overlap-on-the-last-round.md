# Game sounds take audio focus, and the final elimination and victory sounds play on top of each other

- **Noted:** 2026-09-25 — testing `main` (05894ee) on the Pixel with Settings → Sons de jeu on
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

`dumpsys audio` on the Pixel records every sound as a `USAGE_MEDIA` SoundPool player that
requests audio focus (`focus owner … com.vemore.countscore`). `GameSounds`
(`lib/services/game_sounds.dart`) plays through audioplayers with no `AudioContext`, and its
Android default asks for `AndroidAudioFocus.gain`. The likely result (not yet checked by ear)
is that music the players have on in the background pauses at every elimination, and does
not resume.

On the round that ends the game, the last elimination and the victory sound start 160 ms
apart (08:03:23.563 and 08:03:23.722 in the log), so both play at once.

**Fix:** set a global `AudioContext` with
`AndroidAudioFocus.gainTransientMayDuck` (or `none`) and `USAGE_GAME`, so background music
ducks and comes back. When one write both eliminates a player and ends the game, play only
the victory sound.

**Acceptance:**
- With music playing in another app, an elimination ducks it and the music is still playing
  afterwards.
- A unit test on `GameSounds`: a write that eliminates a player and ends the game plays
  `victory` alone.
