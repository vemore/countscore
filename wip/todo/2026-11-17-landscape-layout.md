# Landscape on a phone is the portrait layout stretched sideways

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

**Open question:** which screens beyond the game board need a landscape layout; and whether
landscape stays allowed on the PWA.
