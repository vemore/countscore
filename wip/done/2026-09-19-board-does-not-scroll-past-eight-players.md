# With more than 8 players the board does not scroll sideways, so players 7 and up cannot be reached

- **Noted:** 2026-09-19 — full test pass of the production PWA (fresh Chromium profiles, Playwright, fr-FR at 412 × 860)
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

The 10-player board (#119) lays lanes at their minimum width inside a horizontal
`SingleChildScrollView` (`lib/widgets/board_lanes.dart:208-230`). On the production PWA at
412 px, nothing moves it:
- a touch swipe (CDP touch events in an emulated mobile context). The same synthetic swipe
  does scroll the vertical filter sheet, so the gesture itself is fine;
- a mouse drag, which Flutter web does not treat as a scroll by default;
- Shift + wheel and a horizontal wheel.

Lanes 7 to 10 (Guillaume, Camille, Julie, Marc) stay off-screen
([capture](../assets/2026-09-19-board-does-not-scroll-past-eight-players/ten-players-after-swipe.png)), and their scores can be entered only through
the keypad or the one-row-per-player view. The ranking ribbon above still scrolls in
principle, but it was not checked.

Minor, same screen: on a 1400 px window all 10 lanes fit, yet the ribbon is still drawn,
because it is keyed on the player count (`n <= kBoardMaxFittingLanes`), not on whether the
lanes fit.

**Fix:** find what eats the horizontal drag, for example the outer vertical scroll view or
the lanes' `InkWell`s. Add a widget test that drags the lanes and checks the offset. Accept
mouse and trackpad drags on this scroll view (`ScrollConfiguration` with
`PointerDeviceKind.mouse` and `trackpad`), plus a visible scrollbar on web. Draw the ribbon
only when the lanes actually overflow.

**Acceptance:**
- A widget test at 400 dp with 10 players: `tester.drag` on the lanes moves the horizontal
  offset, and the 10th lane becomes visible.
- On the PWA, a mouse drag and a touch swipe both reveal lane 10.
- At 1400 px with 10 players there is no ribbon and no horizontal scroll.

**Status:** done (2026-09-19) — closed by fix/board-scroll-and-undo-snackbar. The lanes' scroll view takes touch, stylus, mouse and trackpad drags (`_LanesScrollBehavior`) and shows a scrollbar on the web; the ribbon is drawn only when the lanes overflow. A touch swipe already moved the lanes in a local release build under CDP touch emulation — only the mouse drag was broken there. Checked on a local release build at 412 px: a mouse drag and a touch swipe both reveal lane 10; at 1400 px, no ribbon and no scroll.
