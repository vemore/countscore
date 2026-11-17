# Landscape on a phone is the portrait layout stretched sideways

**Status:** done (2026-11-17) — closed by feat/landscape-layout. A window wider than tall and
under `kCompactLandscapeMaxHeight` (500 dp, `lib/utils/compact_landscape.dart`) takes a compact
landscape layout on the board (48 dp app bar, 64 dp lane headers, 36 dp rows, the round button
in a side rail, the keypad sheet in two halves), home (the Resume card as one strip, tighter
cards) and the statistics (filter and hero beside the leaderboard; the player card in two
columns); every other size goes through the portrait code unchanged. At 800x360 the board
shows 6 rounds (1 before with 4 players, 0 with 8), home 2 cards (0), the leaderboard 3 rows
(0): `test/screens/landscape_layout_test.dart`. The PWA manifest no longer locks portrait.
Screenshots, before and after: [board](../assets/2026-11-17-landscape-layout/board-landscape-after.png),
[keypad](../assets/2026-11-17-landscape-layout/keypad-landscape-after.png),
[home](../assets/2026-11-17-landscape-layout/home-landscape-after.png),
[statistics](../assets/2026-11-17-landscape-layout/stats-landscape-after.png),
[player card](../assets/2026-11-17-landscape-layout/card-landscape-after.png), widget-test
renders with the app's fonts — the Pixel was not reachable.

- **Noted:** 2026-11-17 — requested by the user
- **Theme:** large-screen
- **Area:** app
- **Blocks release:** no

Android does not lock the orientation (`android/app/src/main/AndroidManifest.xml` declares
`configChanges` but no `screenOrientation`), so a phone turned sideways gets the portrait
layout on a ~360 dp-high window: the app bar, the round header and the add-round controls eat
most of the height, and the score grid shows two or three rows. The large-screen work of
2026-09-18 (`wip/done/2026-09-16-no-large-screen-layout.md`, `kHomeGridBreakpoint` 600 dp)
branches on **width** only, so a landscape phone (~800 dp wide) already falls into the wide
layout, but nothing reacts to a short height. The PWA manifest asks for `portrait-primary`
(`web/manifest.json:9`).

**Fix:** a landscape layout selected on `orientation == landscape && height < ~500 dp`
(not on width), first for the game board, then home and the statistics: compact app bar,
round header beside the grid rather than above it, denser rows, the add-round entry in a side
rail. Portrait goes through exactly the code path it uses today — the landscape branch is
additive. Decide whether the PWA manifest drops `portrait-primary`.

**Acceptance:**
- Widget tests at 800×360 dp: the board shows at least twice the score rows it shows today,
  with no overflow, on the board, home and the statistics.
- The existing portrait golden/widget tests pass unchanged, with no edited expectation.
- Screenshots on the Pixel 9 Pro XL in both orientations, on the pull request.

**Decided (2026-11-17, the user):** the game board, home and the statistics screen(s) get a
landscape layout; other screens are out of scope (a new `wip/todo_nr/` entry for one clearly
broken in landscape — none found: the standings and New game screens scroll without
overflow at 800x360). The PWA drops `"orientation": "portrait-primary"` from
`web/manifest.json`, so the installed PWA rotates as the Android app does.
