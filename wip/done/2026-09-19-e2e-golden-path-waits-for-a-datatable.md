# The e2e golden path waits for a DataTable the board no longer has

**Status:** done (2026-09-19) — closed by test/e2e-golden-path-keypad. Both waits now use `find.byKey(const Key('board_add_round'))`; nothing else in the test was stale. The web run (`flutter drive … -d web-server --headless`, chromedriver 153, no `BACKEND_URL` so step 7's analysis skips) passed end to end. The device run on the Pixel was not done: the user chose to merge on the web run alone (2026-09-19); it is owed at the next device session (`release-android` §5 or the screenshot retake).

- **Noted:** 2026-09-19 — while moving score entry to the keypad (`feat/score-keypad`)
- **Theme:** testing
- **Area:** app
- **Blocks release:** no

`integration_test/app_test.dart` waits for `find.byType(DataTable)` after creating the game
(step 3) and again when it reopens the board for the analysis (step 7). The board has been
drawn by `BoardLanes` / `BoardRows` since #119, with no `DataTable` anywhere in `lib/`, so
the golden path now times out at step 3, before any score is entered. CI does not run it
(device and chromedriver only, `.llmwiki/Testing.md`), which is how it went unnoticed.

`feat/score-keypad` rewrote step 4 for the keypad sheet but left the two `DataTable` waits
alone, and could not run the suite.

**Fix:** wait for `find.byKey(const Key('board_add_round'))` instead in both places, then
run the suite once on the web (chromedriver) and once on a device.

**Acceptance:**
- `flutter drive … --target=integration_test/app_test.dart` passes on the web, and
  `flutter test integration_test/app_test.dart -d <device>` passes on the Pixel.
