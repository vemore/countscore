# The game-type form still calls a "reaches" rule "first player over"

- **Noted:** 2026-09-19 — rewording `gameRulesEndFirstOver` in feat/game-rules-twelve
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

Since 2026-09-19 `GameOverConditionType.firstPlayerOver` ends a game when a total
**reaches** the threshold (`GameType.isGameOver`, `>=`), and the rules page says so
(`gameRulesEndFirstOver`: « dès qu'un joueur atteint {threshold} points »). The dropdown in
the game-type form (`lib/screens/game_types_screen.dart:293`) still labels the same
option with `firstPlayerOver` — « Premier joueur au-dessus », "First player over" — which
reads as strictly above. A user setting 100 there expects 101 to end the game.

`lastPlayerOver` keeps the strict reading, so its label is correct and the two now differ.

**Fix:** reword `firstPlayerOver` in the ten ARB files (`i18n-add-string`), for example
« Premier joueur à atteindre » / "First player to reach".

**Acceptance:**
- The ten `firstPlayerOver` values say "reaches", not "over"; `arb_keys.py --values` passes.
