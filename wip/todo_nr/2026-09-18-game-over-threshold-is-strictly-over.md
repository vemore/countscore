# A "first player over" threshold ends the game one step later than the rules say

- **Noted:** 2026-09-18 — while seeding Uno (500) and Président (10) in feat/game-rules-seeds
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

`lib/screens/game_board_screen.dart:577-578` ends a `firstPlayerOver` game when a total is
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

**Acceptance:**
- A Président game with a player on exactly 10 is over, or the decision to keep `>` is recorded in the wiki.
- The rules page label and the ten rules texts use the same comparison as the code.
