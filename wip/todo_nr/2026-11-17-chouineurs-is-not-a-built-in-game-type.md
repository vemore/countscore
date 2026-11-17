# Chouineurs is not a built-in game type

- **Noted:** 2026-11-17 — the user asked for it among the default games
- **Theme:** game-types
- **Area:** app | backend
- **Blocks release:** no

Chouineurs (Frédéric Vuagnat, Blam!, April 2026; 3–5 players, ~20 min) is a trick-taking
game played in exactly **4 rounds of 7 tricks**, scored on paper — the box has no score pad,
which is what CountScore is for. Its end rule is a round count, so it **depends on
[[2026-11-17-a-game-type-cannot-end-after-a-fixed-number-of-rounds]]** and ships in the same
pull request (no stacking — CLAUDE.md, Workflow).

**Rules, from the publisher's rules sheet** (`media.play-in.com/pdf/rules_games/chouineurs_fr.pdf`,
read 2026-11-17), to be **summarised in our own words**, never reproduced:
- each round: 7 two-sided cards dealt, each player picks one orientation for the whole hand,
  then secretly picks one of their 5 *Pari* cards; a *Pari* card lists several trick counts,
  each with its own points (e.g. 2 / 3 / 4 tricks → 3 / 9 / 4 points);
- tricks: follow suit; yellow is trump, black (dragons) super-trump and playable at any time;
  the player of the **lowest card** of a trick *chouine* (ties: all of them) and chooses either
  to flip one card of their hand, or to take a card from the reserve worth **1 point**;
- end of round: tricks won equal to one count on the *Pari* card → its points, and that card
  is removed from the game; otherwise 0 and the card comes back; **+1 per card** taken by
  chouining; scores add up across rounds;
- end of game: after round 4, **highest total wins**; tie → most points in the last round.

**Fix:**
1. `GameType.chouineurs()` in `lib/models/game_type.dart`: `builtinKey: 'chouineurs'`,
   `name: 'Chouineurs'`, `rulesSlug: 'chouineurs'`, `isLowestScoreWins: false`, `maxRounds: 4`,
   no threshold, no elimination, no keypad shortcut; icon `Icons.sentiment_very_dissatisfied`
   (a whiner), a colour no other seed uses. **Appended** to `defaultGameTypes()` (append only).
2. Existing installs get the row from the same schema step as the column (`applyV22`): insert
   when no row holds the key and no live row has the name — the `applyV14` step-2 pattern, so
   a user's own "Chouineurs" is kept and not duplicated. `defaultRulesSlugs` gains the key.
3. Displayed name: both switches in `lib/utils/game_type_name.dart` (a proper name, the same
   in every locale). `GameRulesCatalog.slugs` gains `'chouineurs'`.
4. Ruleset: a `chouineurs` section in all 20 `assets/rules/rules_<locale>.md`, same headings
   as the others (Mise en place · Déroulement · Comptage · Fin de la partie).
5. Backend analysis: add the key wherever `backend/app/services/analysis/game_rules.py` keys
   per-type hints, so the commentary knows it is highest-wins over 4 rounds.
6. Docs: the "22 built-in" counts become 23 — `.llmwiki/DataLayer.md:36`, `I18n.md:100`,
   `Schema.md:112`, `MobileApp.md:42`/`577`, `Testing.md:20`/`50`; `README.md` game list.

**Acceptance:**
- A fresh database seeds 23 types, `chouineurs` among them, with `maxRounds == 4`.
- `test/migration_v21_to_v22_test.dart`: an upgrade inserts Chouineurs once; a v21 file that
  already has a live user type named "Chouineurs" gets no second one; a replay inserts nothing.
- `test/game_rules_catalog_test.dart` finds a `chouineurs` section in all 20 rule files.
- A game of Chouineurs with 3 players shows the end screen after its 4th round, not before,
  and ranks the highest total first.

**Open question:** none on the rules. Whether the board shows "Manche n/4" is the open
question of the dependency entry.
