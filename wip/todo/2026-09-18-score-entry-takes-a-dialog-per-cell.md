# Entering a round takes one dialog and one system keyboard per player

- **Noted:** 2026-09-18 — visual refresh, split into one pull request per screen
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

Part of the visual refresh, direction A "Material soigné", chosen from four mock-up directions
(split out of `wip/done/2026-09-18-app-looks-like-a-default-material-template.md`). The images
in [`wip/assets/…material-template/`](../assets/2026-09-18-app-looks-like-a-default-material-template/) are the target (light, and `dark-` prefixed); the
interactive page is https://claude.ai/artifact/D3ycxcgzPxHezRrSrmuxiw (private).

**Target:** [entry, 4 players](../assets/2026-09-18-app-looks-like-a-default-material-template/entry-4-players.png), [entry, 8 players](../assets/2026-09-18-app-looks-like-a-default-material-template/entry-8-players.png), and their `dark-` versions.

"Add round" inserts an empty row (`game_board_screen.dart:518`). Each cell then opens an
`AlertDialog` with a signed `TextField` (`game_board_screen.dart:922-990`) and the system
keyboard, followed by "Save". That is four gestures per score, so 16 per round at 4 players,
and a round abandoned halfway leaves empty cells.

Lands after [[2026-09-18-board-hides-who-owns-each-column-and-who-leads]] (merged in #119): same
screen. The cells are now drawn by `lib/widgets/board_lanes.dart` and `board_rows.dart`.

**Fix:** a **keypad bottom sheet** (a new widget in `lib/widgets/`).
- **"Round N" opens it** on the first player in seat order, skipping eliminated players. It
  shows the players as chips (current one outlined in their colour, with the scores already
  typed), a large number, the total after this score, and a 0-9 pad with ± and ⌫.
- "Next" moves to the following player. On the last player it becomes "Validate round",
  which writes the round **in one go**: no empty row is created before validation. Closing
  the sheet drops the unsaved round.
- **For ZapZap only**, the bottom-left key reads "0 ZapZap". For other games it is a plain
  "0" (per-game shortcuts: [[2026-09-18-keypad-has-no-per-game-shortcut]]).
- **Tapping an existing cell** opens the same sheet on that one score, with "Save" in place
  of "Next".
- The per-cell `AlertDialog` and its `TextField` are removed.

**Acceptance:**
- Widget test: a full 4-player round is entered through the keypad with no `TextField` in the
  tree, and one round row exists only after "Validate round".
- Widget test: closing the sheet halfway leaves the round count unchanged.
- Widget test: editing a past cell through the sheet updates that score and its total.
- Widget test: the "0 ZapZap" label appears for ZapZap and not for Tarot.
