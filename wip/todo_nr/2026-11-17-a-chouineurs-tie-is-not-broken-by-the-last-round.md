# A Chouineurs tie is not broken by the last round

- **Noted:** 2026-11-17 — while adding Chouineurs as a built-in type (feat/max-rounds-chouineurs)
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

The box rule breaks a tie on the total by **the most points in the last round**
(`assets/rules/rules_fr.md`, section `chouineurs`, "Fin de la partie"). CountScore ranks a
finished Chouineurs game by the total alone (`GameStanding.forGame`,
`lib/models/game_standing.dart`, `RankingRule.score`): two players on the same total share
the place, the headline names both, and the statistics count a shared win. The rules text the
app ships therefore promises a winner the standings do not name.

**Fix:** a per-type tie-break, not a Chouineurs special case: a nullable game-type field (or
an enum value) "ties broken by the last round", read by `outranksUnder` after the total, so
the standings, the end headline and `FinishedGameResult` (the statistics) agree. It is a
synced column: schema step, Alembic revision, lane C. Or, cheaper, say in the rules text that
CountScore shows a tie and the table settles it.

**Acceptance:**
- A finished Chouineurs game where Alice and Bob end on 27, Bob with more in round 4, names
  Bob alone and ranks him first, on the standings and in the statistics.
- A tie in total *and* last round still shares the place.
