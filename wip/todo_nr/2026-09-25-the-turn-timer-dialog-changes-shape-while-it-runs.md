# The turn timer dialog changes shape when it starts, pauses and ends

- **Noted:** 2026-09-25 — testing `main` (05894ee) on the Pixel, in French
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

Stopped, the timer dialog shows "Réinitialiser · Démarrer · Fermer" on one row. Running, the
primary button becomes "Mettre en pause", the three actions no longer fit in one row, and the
`AlertDialog` stacks them in a right-aligned column: the dialog grows by about a hundred
pixels and moves up, so the button under the finger changes place between two taps. At 0:00
it goes back to one row, with "Temps écoulé !" added. Seen in `game_board_screen.dart`'s timer
dialog; German and Russian labels are longer still.

**Fix:** give the dialog a fixed layout. For example, put start/pause as a full-width
button under the time, with Reset and Close as text buttons in the actions, and keep a
fixed-height slot for "Temps écoulé !".

**Acceptance:**
- A widget test at 360 dp wide in `fr`, `de` and `ru` finds the dialog the same size when
  stopped, running and at zero.
