# Eliminated players have no skull on the board

**Status:** done (2026-09-24) — closed by feat/board-skull-sounds-timer. `BoardSkull` (painted, since the pinned Material Icons font has no skull; label `boardEliminated` in the ten ARB files) takes the crown's place above an eliminated player's avatar in lanes and rows, through `boardMark`, and wins over the crown. Tested in `test/screens/game_board_skull_test.dart`.

- **Noted:** 2026-09-23 — user request
- **Theme:** growth
- **Area:** app
- **Blocks release:** no

In a game type configured with elimination, an eliminated player is only greyed out
(opacity 0.5) and struck through: `lib/widgets/board_lanes.dart:389-474` (lanes) and
`lib/widgets/board_rows.dart:266-291` (rows). The leader gets a trophy above the avatar
(`BoardCrown`, `board_lanes.dart:153`). The user wants the same kind of mark for the
eliminated: a small skull above the player's avatar, so they can be spotted at a glance.

**Fix:** a `BoardSkull` next to `BoardCrown`, the same size and position, with a
`Semantics` label (new string via `i18n-add-string`, 10 locales). Shown in both layouts
wherever `data.isEliminated(total)` is true, and only for game types with elimination.
Icon candidates: a Material Symbols skull (check the pinned icon font has one; the web build
self-hosts fonts) or a small bundled SVG. If a player is somehow both leader and
eliminated, the skull wins.

**Acceptance:**
- Widget test: in an elimination game type, a player past the threshold shows `Key('board_eliminated_skull')` in lanes and in rows, and a player below it does not.
- Widget test: a game type without elimination never shows the skull.
- The skull's semantics label exists in the ten ARB files.
