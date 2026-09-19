# A "first player over" threshold ends the game one step later than the rules say

**Status:** done (2026-09-19) — closed by feat/game-rules-twelve. `firstPlayerOver` is `>=` (`GameType.isGameOver`, which the board now calls); `gameRulesEndFirstOver` says "reaches" in ten languages and the Uno and Président texts no longer say "passes". Existing Skyjo and Belote games now end one step earlier. Tested in `test/models_test.dart` (Président on 10 is over, on 9 is not) and `test/screens/game_board_end_of_game_test.dart`.

- **Noted:** 2026-09-18 — while seeding Uno (500) and Président (10) in feat/game-rules-seeds
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

`lib/screens/game_board_screen.dart:558` ends a `firstPlayerOver` game when a total is
strictly **greater** than the threshold (`total > gameOverThreshold`), and the rules page
says so (`gameRulesEndFirstOver`: « dès qu'un joueur dépasse {threshold} points »). The
rules the thresholds come from say **reaches**: Uno is won at 500, Président at 10, Skyjo
stops at 100 or more. For Uno it rarely matters, but Président scores in steps of 1 and 2,
so a player sitting on exactly 10 has won by the box rule while CountScore asks for another
hand. The rules texts currently state both readings side by side ("atteindre 10" / "dès
qu'un total passe 10").

**Fix:** decide whether `firstPlayerOver` means `>=` (and reword the ARB label in ten
languages), or keep `>` and seed 499 / 9 / 99 — which reads oddly on the rules page. The
first is cleaner; it changes when existing Skyjo and Belote games end, which needs saying.

**Decided (2026-09-18, refinement 3):** `>=`. `firstPlayerOver` means "reaches"; the
label `gameRulesEndFirstOver` is reworded in ten languages, and the pull request says that
existing Skyjo and Belote games now end one step earlier.

**Acceptance:**
- A Président game with a player on exactly 10 is over (widget or unit test); one on 9 is not.
- The rules page label and the ten rules texts use the same comparison as the code.
