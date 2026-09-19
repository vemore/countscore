# Every store locale's screenshots show the French UI

- **Noted:** 2026-09-18 — while composing the ten per-locale screenshot sets (`feat/composed-screenshots`)
- **Theme:** store-listing
- **Area:** docs
- **Blocks release:** no

`scripts/compose_screenshots.py` localizes only the caption band. The screen under it comes
from the one shared set of raw captures in `store_listing/assets/screenshots/phone/`, taken
with the phone in French. So the `ja-JP`, `ar` or `hi-IN` visitor reads a caption in their
language above « Liste des joueurs », « Nouvelle partie » and a French keyboard, even though
the app itself ships in their language.

**Fix:** let the composer read `store_listing/<locale>/raw/*.png` before the shared set, and
capture each locale with the device (or an emulator) switched to that language
(`scripts/capture_screenshots.sh` with a locale argument, `adb shell cmd locale` or the
per-app language setting). Players and game names in the demo data can stay the same. The retake of 04 below happens in
the same session.

**Absorbed (2026-09-18, refinement 4):** [[2026-09-18-screenshot-04-duplicates-01]].
`store_listing/assets/screenshots/phone/04_game_history.png` is the main game list, the same
screen and games as `01_main_screen.png`: there is no history screen distinct from home. Retake
04 as a finished game's score sheet (the end-of-game podium or final totals), or as a screen the
carousel lacks (AI analysis, group sharing), and adjust the `04_*` caption in every
`screenshot_captions.txt`. All eight captures predate the visual refresh, so all eight are
retaken, in every locale, in one device session.

**Decided (2026-09-18, refinement 4):** one entry, and the retake waits until
[[2026-09-18-app-theme-is-default-deep-purple]] and
[[2026-09-18-board-hides-who-owns-each-column-and-who-leads]] have landed (not the end screen
or keypad).

**Absorbed (2026-09-19, refinement 5):** [[2026-09-18-store-screenshots-show-the-old-purple-theme]].
The raw captures still show the violet app, and `scripts/compose_screenshots.py:55` draws the
caption band on `BACKGROUND = (0x67, 0x3A, 0xB7)  # Deep Purple 500`, described as "the app's seed
colour". Move that gradient to the teal (`#0E8F88`, `lib/utils/app_theme.dart`), then re-compose
the ten locales, and publish with `play_publish.py listing --graphics` (`release-android`) once
the user asks for it. Remove the Outdated block from `.llmwiki/StoreListing.md`.

**Decided (2026-09-19, refinement 5):** the retake waits until
[[2026-09-18-score-entry-takes-a-dialog-per-cell]] and
[[2026-09-18-finishing-a-game-has-no-end-screen]] have landed too. Otherwise `07_score_entry`
would show the old dialog, and the retake of 04 would have no podium to show. This replaces the
refinement 4 decision above.

**Acceptance:**
- No two raw captures of one locale show the same screen.
- The composed `ja-JP` set shows the Japanese UI under the Japanese caption.
- `compose_screenshots.py --check` still exits 0 on all ten locales.
- `compose_screenshots.py` has no deep-purple colour; its gradient derives from `#0E8F88`.
- Every `store_listing/<locale>/screenshots/phone/` image shows the teal theme, the keypad sheet and the end screen.
- `.llmwiki/StoreListing.md` no longer carries the Outdated block about the caption colour.
