# The shipped ZapZap rules stop at the scoring, because nothing documents the play

- **Noted:** 2026-09-16 — while writing the rules text for the game-rules page
- **Theme:** game-types
- **Area:** docs
- **Blocks release:** no

Eight of the nine shipped rulesets were written from public sources. ZapZap has none: it is
the author's family game. The only description that exists anywhere in the project is the
context block of `ZAPZAP_SYSTEM_PROMPT` (`backend/app/services/zapzap_prompt.py:24-31`),
which covers the scoring exactly — the ZapZap call, 0 points when it lands, hand plus
(players − 1) × 5 when it is missed or countered, elimination above 100, final ranking as
the reverse of the elimination order, and the two-player golden score at 101.

It says nothing about the deal, the draw, or what may be played on a turn. Rather than
invent those, `assets/rules/rules_fr.md` ends the `zapzap` section with a paragraph saying
the play details belong to the table and pointing at the edit button. That is honest but it
is the thinnest of the nine, in all ten languages.

**Fix:** get the missing half from the author — deal size, draw and discard, when the
ZapZap call is allowed, what a counter is — and extend the `zapzap` section of
`assets/rules/rules_fr.md`, then re-run the nine translations. The catalogue test
(`test/game_rules_catalog_test.dart`) already guards the structure, so the risk is only in
the prose. Worth doing before the next Play release: ZapZap is the first type in the list
and the one the store screenshots show.

**Answered (2026-09-18, refinement):** the complete rules are the author's own, in the
ZapZap project's `GAME_RULES.md` (outside this repository; ask the user for it). ZapZap is a
variant of Yaniv. That file covers the card values, the valid combinations, the turn, the
round start, the empty deck, ZapZap eligibility, the scoring, elimination and the golden score.

**Acceptance:**
- The `zapzap` section of `assets/rules/rules_fr.md` covers the deal, the turn (draw, discard, valid combinations), when ZapZap may be called, what a counter is, and the scoring.
- The nine translations follow, and `test/game_rules_catalog_test.dart` is green.
- Nothing in it contradicts the scoring in `backend/app/services/zapzap_prompt.py`.
