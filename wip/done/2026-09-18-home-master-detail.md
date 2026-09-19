# The home screen is a single column of game cards at any width

**Status:** done (2026-09-19) — closed by feat/home-card-grid. From `kHomeGridBreakpoint` (600 dp, `lib/screens/home_screen.dart`) the Recent cards form a grid of `homeGridColumns(width)` columns (at least two; 3 at 1200 dp, 4 at 1600), rows of equal-height cards under a full-width Resume card; a grid card under 360 dp moves its status pill under the name. `test/screens/home_screen_grid_test.dart` pins 400 and 1200 dp, and no overflow from 320 to 1600 dp; the 1600 px PWA screenshot is on the pull request.

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
