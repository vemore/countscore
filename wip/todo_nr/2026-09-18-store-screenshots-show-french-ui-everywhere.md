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
per-app language setting). Players and game names in the demo data can stay the same. Best
done in the same session as the re-capture in
`wip/todo_nr/2026-09-18-screenshot-04-duplicates-01.md`.

**Acceptance:**
- The composed `ja-JP` set shows the Japanese UI under the Japanese caption.
- `compose_screenshots.py --check` still exits 0 on all ten locales.
