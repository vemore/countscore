# Store screenshot 04 "game history" shows the same screen as 01

- **Noted:** 2026-09-18 — while composing the captioned screenshots (`feat/composed-screenshots`)
- **Theme:** store-listing
- **Area:** docs
- **Blocks release:** no

`store_listing/assets/screenshots/phone/04_game_history.png` is the main game list — the same
screen, same games (p133 … p130), as `01_main_screen.png`. There is no history screen distinct
from the home list, so the capture repeats slide 1 and spends one of the eight carousel slots
on nothing new. Its caption ("Retrouvez chaque partie terminée") fits, but the image does not
show a finished game's score sheet. Also, the captures predate the visual refresh
(`wip/todo_nr/2026-09-18-app-looks-like-a-default-material-template.md`).

**Fix:** re-capture 04 as a finished game's score sheet (the podium or final totals), or a
screen the carousel lacks (the AI analysis, group sharing), with `scripts/capture_screenshots.sh`,
adjust the `04_*` caption in every `screenshot_captions.txt`, and re-run
`scripts/compose_screenshots.py`. Best done after the visual refresh, once for all eight.

**Acceptance:**
- No two raw captures in `store_listing/assets/screenshots/phone/` show the same screen.
