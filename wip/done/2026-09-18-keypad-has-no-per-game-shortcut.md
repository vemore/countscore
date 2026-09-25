# The score keypad has a shortcut key for ZapZap only

**Status:** done (2026-09-25) — closed by feat/keypad-game-shortcuts. A game type carries a
`KeypadShortcut` (value, multiply or add, a number, an optional label) in
`game_types.keypad_shortcut` (schema v21, server `0006_game_type_keypad_shortcut`), synced and
validated on both sides; the five decided shortcuts are seeded and back-filled, the editor sets
it on any type, and the keypad shows it bottom-left. ×2 applies to the score typed, positive
scores only.

- **Noted:** 2026-09-18 — deciding the keypad of the visual refresh
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

[[2026-09-18-score-entry-takes-a-dialog-per-cell]] gives the keypad a "0 ZapZap" key for ZapZap
only; every other game gets a plain "0". Other built-in games have a score typed often
enough to deserve a key of its own. The examples below are hypotheses to check against the
rules in `assets/`: Skyjo's −2 card or its doubling of the closer's score, Uno's 0 for the
player who went out, Yahtzee's 50.

**Fix:** a per-game-type shortcut: a label and a value, or an operation such as doubling. It
is set on the built-in types (`lib/models/game_type.dart`) and editable on custom types in
`game_types_screen.dart`. This probably means a schema change (the `db-migration` skill),
which is synced.

**Decided (2026-09-18, refinement 4):** a shortcut is either a value or an operation (such as ×2).

**Decided (2026-09-19, refinement 5):** checked against `assets/rules/rules_fr.md`:

| Type | Key | Kind | Why |
|---|---|---|---|
| ZapZap | "0 ZapZap" | value 0 | the key [[2026-09-18-score-entry-takes-a-dialog-per-cell]] already ships |
| Skyjo | "×2" | operation | the player who closed the round is doubled when not strictly lowest (positive scores only) |
| Belote | "162" | value | the defending side takes 162 when the taker is *dedans* |
| Scrabble | "+50" | operation | seven letters in one move |
| Rami | "100" | value | the flat penalty for a player who laid nothing down |

No shortcut for Uno (the 0 for the player who went out is a plain 0), Président (2 and 1),
Tarot or Bridge. Skyjo's −2 is a card value, not a round score. Yahtzee and the other types
without rules in `assets/rules/` are decided once their rules land (`feat/game-rules-seeds`).

**Unblocked (2026-09-20, refinement):** [[2026-09-18-score-entry-takes-a-dialog-per-cell]] is
closed and the keypad shipped as `lib/widgets/score_keypad_sheet.dart`, still ZapZap-only —
the `isZapZap` bool threaded through `:60`/`:75`/`:93`/`:117`/`:312`, `_zapZap()` at
`:201-202` and the key itself at `:532-543` (`'keypad_zapzap'`, `l10n.keypadZeroZapZap`).
Nothing waits on anything now; what is left is the per-game-type column and the five keys
decided below.

**Acceptance:**
- Widget test: in a Skyjo game, typing 12 then "×2" enters 24; in a Belote game, "162" enters 162.
- Widget test: a Tarot game's keypad shows a plain "0" and no shortcut key.
- A custom type's shortcut set in `game_types_screen.dart` survives a restart and reaches another device through sync.
- The migration test for the new column passes (`db-migration`).
