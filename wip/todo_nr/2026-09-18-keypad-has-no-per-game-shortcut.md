# The score keypad has a shortcut key for ZapZap only

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

**Open question:** which built-in games get which shortcut? Check the hypotheses above against the rules in `assets/rules/` and propose the list.
