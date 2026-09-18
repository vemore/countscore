# The board has no turn timer

- **Noted:** 2026-09-18 — split out of `wip/done/2026-09-16-no-dice-timer-first-player-helpers.md` when feat/board-growth shipped **Who starts?** alone
- **Theme:** growth
- **Area:** app
- **Blocks release:** no

The third of the table helpers the 2026-09-18 refinement ordered one pull request at a time,
after **Who starts?** (done) and the dice roller
(`wip/todo_nr/2026-09-18-no-dice-roller-on-the-board.md`): a per-turn countdown with a sound,
for the tables that need one ("minuteur" in Play search).

**Fix:** a countdown reachable from the board's overflow menu: pick a duration, start,
pause, reset; a sound (`SystemSound` or a bundled asset) at zero. It must keep running
while the dialog is open without holding the board's `State` hostage, and the screen already
stays awake (`wakelock_plus`). Every string through `i18n-add-string`, no permission.

**Acceptance:**
- The board's overflow menu has a turn-timer item that counts down from the chosen duration and signals zero.
- A widget test with `tester.pump(Duration)` checks the countdown reaches zero and resets.
- Every string exists in the ten ARB files; no permission, schema or network change.

**Open question:** remember the last duration per game type, or one global value?
