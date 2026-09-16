# The 10 built-in game types miss the games people actually search for

- **Noted:** 2026-09-16 — while writing the per-game keywords for the store listing
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

`GameType.defaultGameTypes()` (`lib/models/game_type.dart:217`) seeds exactly ten types:
ZapZap, Uno, Scrabble, Autre, Skyjo, Président, Belote, Tarot, Bridge, Rami.

The store search says the demand is elsewhere. « skyjo » alone returns more than ten
dedicated counters, and the queries that bring a counter app its installs are per-game ones.
Absent from the seed although they have their own scoring rule the app could pre-fill:
**Coinche** (Belote with a bid), **Yahtzee**, **Phase 10**, **Flip 7**, **Mille Bornes**,
**Rummikub**, **6 qui prend / 6 nimmt!**, **Qwirkle**, **Farkle**, **Canasta**, **Wizard**,
**Triomino**. Each is a `GameType` row: a name, an icon, a colour, `isLowestScoreWins`, and
optionally a `playerDeadThreshold` or `gameOverThreshold` — the same shape as the ten that
exist. A listing that promises "works for your games of Yahtzee" while the app offers no
Yahtzee type is a conversion leak and, worse, a claim a reviewer can call misleading.

Second defect found in the same file: **the seeded names are hardcoded literals, not
localized** — a Japanese user gets `Autre`, a French word, and every other name in French or
English spelling. They are user-editable rows once written, so the fix is to seed the
*first-run* names from `AppLocalizations` rather than to translate rows after the fact.

**Fix:** extend `defaultGameTypes()` with the games above (generic rules only, no
reproduction of any published rulebook), seed the names from the current locale at first run,
and add the migration that offers the new types to existing installs without resurrecting
types the user deleted — `db-migration` covers the schema side. Keep the trademark care of the
store copy: these are game *names* used descriptively, never "official".
