# The ranking and the end screen still draw one-letter avatars

**Status:** done (2026-09-19) — closed by fix/player-avatars-colours-keypad. Once fix/elimination-and-crown (#149) had merged, `game_ranking.dart` passed `letters: 2` to both the podium and the row avatars; `test/screens/ranking_screen_test.dart` finds each player's two letters.

- **Noted:** 2026-09-19 — while giving the keypad, the home hero and the Players screen the board's two-letter avatars (fix/player-avatars-colours-keypad)
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

`lib/widgets/game_ranking.dart` builds its podium avatars (`:236`) and its row avatars
(`:340`) with `PlayerAvatar`'s default `letters: 1`, so Lionel and Laurent both read "L" on
the ranking and the end screen, while the board, the keypad, the home cards, the Players
screen and the statistics show "Li" and "La". It was left out of that pull request because
another one (fix/elimination-and-crown) was changing `game_ranking.dart` at the same time.

**Fix:** pass `letters: 2` at both call sites — or make two the default of `PlayerAvatar`
once no caller wants one letter, and drop the parameter from the callers that pass 2.

**Acceptance:**
- A widget test: the ranking screen shows "Li" and "La" for Lionel and Laurent, podium and rows.
