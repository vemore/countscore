# The home screen is a single column of game cards at any width

- **Noted:** 2026-09-18 — split out of `2026-09-16-no-large-screen-layout.md` when its board half shipped (feat/board-wide-layout)
- **Theme:** large-screen
- **Area:** app
- **Blocks release:** no

The game board uses the full width (lanes capped at 180 dp and centred since #119,
`lib/screens/game_board_screen.dart`), but `lib/screens/home_screen.dart` is still one column
of full-width cards: on the PWA at 1600 px a game card is a 1 568 px strip holding a name, a
date and a player list (checked 2026-09-18). The 2026-09-18 refinement deferred master-detail
on the home screen to its own entry, "if still wanted".

**Fix:** above 600 dp, a multi-column grid of the same cards (the Resume card keeps the full
width), with the breakpoint as a named constant in `home_screen.dart`.

**Decided (2026-09-18, refinement 4):** a card grid, not master-detail.

**Changed (2026-09-19, refinement 5):** #119 (the lanes board) removed `kBoardWideBreakpoint` and
`isBoardGridWide`: the board now caps its lanes at 180 dp and centres them, and no constant is
left to reuse. **Decided:** home gets its own 600 dp constant in `home_screen.dart`.

**Acceptance:**
- Above 600 dp, home lays the game cards out in more than one column; below it, one column as today (widget tests at 400 and 1200 dp).
- A PWA screenshot at 1600 px is attached to the pull request.
