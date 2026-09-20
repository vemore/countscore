# The game-type editor leaks its controllers, and its name, icon and colour inputs accept what the rest of the app cannot render

**Status:** done (2026-09-20) — closed by fix/game-type-editor. The dialog body is a `StatefulWidget` with a real `dispose`; the name is trimmed on save and the field capped at 64; the icon grid marks the current icon and holds the two seeded glyphs it lacked (`style_outlined`, `change_history`); the colour wheel is gone, replaced by `kGameTypePalette` (`lib/utils/game_type_appearance.dart`) — 18 swatches whose contrast is tested against both themes, with the type's own colour shown as an extra swatch when it is outside the set, so no existing type is recoloured; and the "name required" error is on the field, not in a snackbar drawn behind the barrier.

- **Noted:** 2026-09-20 — reviewing the game-type editor at the user's request
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

Five small defects in `_showGameTypeDialog` (`lib/screens/game_types_screen.dart`), one entry
because they are one screen and one pull request.

**The three `TextEditingController`s are never disposed.** They are created in the function
body (`:146`, `:149`, `:152`) and the dialog closes without a `dispose` anywhere in the file.
Every open of the editor leaks three. `CLAUDE.md` asks the opposite: *dispose controllers and
listeners*. A `StatefulWidget` for the dialog body, or a `dispose` on the returned future.

**The name is neither trimmed nor bounded.** `nameController.text` is saved raw. A trailing
space survives into the row, and since the server enforces `unique(group_id, name)`
(`backend/app/models/game.py:22`), "Belote" and "Belote " are two types in a group. Worse,
`isBuiltinRename` (`lib/utils/game_type_name.dart:149`) compares *trimmed*, so typing a trailing
space on a built-in type is not a rename — the key is kept and the stored name silently gains a
space nobody reads. There is no `maxLength` either, while the server column is
`max_length=64`: a longer name is clipped on push, so the group sees a truncated type and this
device does not. Trim on save, cap the field at 64, and only the name is left to check for
emptiness — which it already is.

**The icon picker does not show which icon is current, and cannot reach two of the seeded
ones.** The 32-icon grid (`:436`) has no selected state, so the user cannot see what they are
replacing. Two built-in icons are missing from it — `Icons.style_outlined` (Rami) and
`Icons.change_history` (Triomino) — so opening either type and changing the icon is one-way.
Add the two, and mark the current one.

**The colour picker accepts a colour the icon disappears into.** The wheel returns any ARGB,
and the colour is drawn at full opacity as the type's icon over a surface-coloured card
(`:64`, and `lib/widgets/game_type_tile_grid.dart:103` and `:186`). Near-white is invisible in
the light theme, near-black in the dark one, and both themes must work. Either restrict the
picker to the primary swatches that already pass, or blend the chosen colour towards a legible
contrast when it is drawn.

**The "name required" snackbar is drawn behind the dialog.** `ScaffoldMessenger.of(context)`
(`:355`) reaches the app's messenger, so the snackbar appears under the modal barrier while the
dialog stays open. Put the error on the field instead — the same place
[[2026-09-20-a-condition-saves-without-a-threshold-and-does-nothing]] needs.

**Acceptance:**
- No controller outlives the dialog (a test that opens and closes it 100 times does not grow).
- A name saved with surrounding spaces is stored trimmed, and the field stops at 64 characters.
- The icon grid marks the current icon, and every icon in `GameType.defaultGameTypes()` is in it.
- A colour chosen in the picker keeps the type's icon legible in both themes (contrast checked in a test).
- Saving with an empty name marks the field, with no snackbar.
