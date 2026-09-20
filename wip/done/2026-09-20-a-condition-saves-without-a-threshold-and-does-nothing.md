# A game-type condition saves without a threshold and then does nothing, while the editor still shows it as chosen

**Status:** done (2026-09-20) — closed by fix/game-type-editor. A threshold is required as soon as a condition type is chosen, refused as a field error; both fields carry `FilteringTextInputFormatter.digitsOnly` and stop at `kMaxGameTypeThreshold` (1000000), so no letter and no negative value reaches the controller. Clearing the condition back to *Aucune* clears the threshold and writes both as NULL. Rows that already hold a condition with a NULL threshold are still read as "no condition".

- **Noted:** 2026-09-20 — reviewing the game-type editor at the user's request
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

Both condition blocks of `_showGameTypeDialog` (`lib/screens/game_types_screen.dart`) let the
type be chosen and the threshold left out:

```
playerDeadThreshold: playerDeadThresholdController.text.isEmpty
    ? null : int.tryParse(playerDeadThresholdController.text),
```

Nothing refuses an empty field, and `int.tryParse` turns anything non-numeric into the same
`null` — the field carries `keyboardType: TextInputType.number`, which is a keyboard hint, not
a constraint, and there are no `inputFormatters` (nor a `maxLength`, nor a lower bound). A
negative threshold is accepted as readily.

The stored row then holds a condition type with a null threshold, and every reader treats it as
*no condition*: `GameType.isEliminated` and `isGameOver` return false on `threshold == null`,
and the rules screen prints `gameRulesNoElimination` / `gameRulesNoEnd`
(`lib/screens/game_rules_screen.dart:222`). So the editor reopens showing *Au-dessus du seuil*
while the rules screen says *Aucune élimination* and the board never eliminates anyone. Nothing
anywhere says why.

**Fix:** make the threshold required as soon as a condition type is picked — refuse the save
with the field in error rather than a snackbar, since the snackbar is drawn behind the dialog
([[2026-09-20-the-game-type-editor-leaks-its-controllers-and-validates-nothing]]) — and
constrain the input: `FilteringTextInputFormatter.digitsOnly`, a sane upper bound, and no
negative value. Clearing the condition back to *Aucune* already clears the field, which is the
right half of the behaviour and can stay.

**Acceptance:**
- Choosing a condition type and leaving the threshold empty cannot be saved; the field shows the error.
- Letters typed into a threshold on the web build do not reach the controller.
- A type saved with a condition always has a threshold, so the editor, the rules screen and the board agree (widget test over the three).
- The existing rows that already hold a type with a null threshold are read as "no condition", unchanged.
