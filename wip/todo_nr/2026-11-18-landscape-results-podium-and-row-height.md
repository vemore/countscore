# Landscape: the results podium fills the screen, and board rows stay 52 dp high

- **Noted:** 2026-11-18 — device test of the compact landscape layout on a Xiaomi (M2007J3SG, ~411 dp high)
- **Theme:** large-screen
- **Area:** app
- **Blocks release:** no

Two screens still take the portrait sizing on a phone on its side (`compactLandscapeOf`):

- **Results** (`Résultats`): the podium and the title text fill the window, so the names and
  scores of 2nd and 3rd are below the fold; one scroll reveals them, with the list under.
- **Rows board** (`BoardRows`): the rows are 52 dp (`_rowHeight`) and the header 32 dp, so
  with 5 players only 4 rows are in full. The lanes board has a dense 36 dp row for this case.

**Fix:** a compact variant of each: a podium laid out beside the title, and a smaller
`_rowHeight` / `_headerHeight` in `BoardRows` under `compactLandscapeOf`.

**Acceptance:**
- Widget tests at 800x360: the podium shows all three names, and the rows board shows at least
  5 players' rows in full, no overflow.
- Portrait goldens and widget tests pass unchanged.
