# The home screen is a single column of game cards at any width

- **Noted:** 2026-09-18 — split out of `2026-09-16-no-large-screen-layout.md` when its board half shipped (feat/board-wide-layout)
- **Theme:** large-screen
- **Area:** app
- **Blocks release:** no

The game board's score grid now uses the width above 600 dp (`kBoardWideBreakpoint`,
`lib/screens/game_board_screen.dart`), but `lib/screens/home_screen.dart` is still one column
of full-width cards: on the PWA at 1600 px a game card is a 1 568 px strip holding a name, a
date and a player list (checked 2026-09-18). The 2026-09-18 refinement deferred master-detail
on the home screen to its own entry, "if still wanted".

**Fix:** above the same breakpoint, either a master-detail (the list on the left, the selected
game's board on the right) or, cheaper, a multi-column grid of the same cards. Reuse
`kBoardWideBreakpoint` / `isBoardGridWide` rather than a second constant.

**Open question:** master-detail, a card grid, or nothing — is the home screen worth it before
the tablet screenshots are captured?
