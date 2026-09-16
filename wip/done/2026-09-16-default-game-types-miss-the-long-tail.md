# The 10 built-in game types miss the games people actually search for

**Status:** done (2026-09-16) — closed by feat/game-types-long-tail. Both halves: `defaultGameTypes()` seeds **22** types (the twelve are appended, so the first ten indices are unchanged for an existing install), and a built-in type's displayed name now comes from `game_types.builtin_key` through `lib/utils/game_type_name.dart` rather than from the stored literal. The entry proposed seeding the names from the current locale at first run; that was **not** done, because the row would then freeze the locale of the day it was written and a device that changes language, or a second device in another language, would still be wrong. `builtinKey` carries the identity *and* the name instead, which also makes last-writer-wins on `name` harmless across locales (schema v13, server revision `0003_game_type_builtin_key`). Renaming a built-in type clears its key, so a user's own name still wins. The migration back-fills the ten seeded rows by name and only inserts types that never existed locally, so nothing the user deleted comes back.

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
