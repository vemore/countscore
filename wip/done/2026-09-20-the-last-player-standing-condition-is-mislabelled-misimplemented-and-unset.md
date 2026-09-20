# "Last player over" says last player standing, does not do it, and is set on no built-in type

**Status:** done (2026-09-20) — closed by feat/last-player-standing. `GameType.isGameOver`
ends the game once every total but one is past the threshold (`_lastPlayerStanding`, a table
of fewer than two players excluded); the two choices are relabelled to the situation in all
ten languages, keys unchanged; and `zapzap`, `rami` and `six_nimmt` are seeded
`lastPlayerOver` at their elimination threshold (100, 100, 65), on a new database only.

- **Noted:** 2026-09-20 — reported by the user; labels and seeds read out of `lib/l10n/` and `lib/models/game_type.dart`
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

Three problems stacked on the same setting, *Condition de fin de partie* in the game-type
editor (`lib/screens/game_types_screen.dart:292`).

**The description and the code disagree.** `gameRulesEndLastOver` promises "La partie s'arrête
quand **tous les joueurs sauf un** dépassent {threshold} points" — that is last player
standing, and it is what the rules screen shows. `GameType.isGameOver`
(`lib/models/game_type.dart`, `GameOverConditionType.lastPlayerOver`) tests
`totals.every((total) => total > threshold)` — **every** player, the survivor included. Since a
player who is out stops being dealt in, the survivor's total never moves and the condition
never fires. `lastPlayerUnder` has the same shape and the same gap.

**The label does not read as what it is.** *Dernier joueur au-dessus* / "Last player over"
describes the arithmetic, not the situation. What a user is choosing is "the game ends when
only one player is left".

**And it is set on no built-in type.** The three types that actually play to a last survivor —
`zapzap`, `rami`, `six_nimmt`, the only ones with a `playerDeadConditionType` — leave
`gameOverConditionType` null. That is why a ZapZap game with one player left still offers
another round (seen on the PWA, [[2026-09-20-ranking-ignores-the-game-types-ranking-rule]]).
The other types with no condition — `scrabble`, `tarot`, `bridge`, `yahtzee`, `phase10`,
`rummikub`, `qwirkle`, `wizard`, `triomino`, `other` — genuinely have no automatic end, and
stay as they are.

**Fix:** make the code match the description — out once every player **but one** is past the
threshold — rename the two choices to the situation they describe (*Dernier joueur en jeu* /
"Last player standing", and its under twin), and seed `lastPlayerOver` with the elimination
threshold on `zapzap`, `rami` and `six_nimmt`. As with Uno and Président
(`game_type.dart:235`), no migration rewrites an existing row: only a new database seeds it,
and a user type that already carries `lastPlayerOver` gains the behaviour its own description
already claimed. Labels go through the `i18n-add-string` skill — 10 languages.

**Acceptance:**
- A four-player ZapZap where three players are past 100 and one is not offers to end the game; before the third is out, it does not.
- `lastPlayerUnder` behaves symmetrically, and `firstPlayerOver` / `firstPlayerUnder` are unchanged (regression test).
- The rules screen's sentence and `isGameOver` agree, checked by a test that reads both.
- A new database seeds the three elimination types with the condition; an existing one is untouched.

This entry is a prerequisite for
[[2026-09-20-ranking-ignores-the-game-types-ranking-rule]]: the elimination order only applies
to a type that has an elimination threshold **and** ends on the last player standing, which no
type can express until this lands.
