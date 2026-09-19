# The store screenshots still show the deep-purple theme, under a deep-purple caption band

**Status:** dropped (2026-09-19) — merged into [[2026-09-18-store-screenshots-show-french-ui-everywhere]]: the same device session and the same re-composition.

- **Noted:** 2026-09-18 — while moving the app to the teal theme (`feat/theme-refresh`)
- **Theme:** store-listing
- **Area:** android
- **Blocks release:** no

The app's look is teal "Material soigné" since `feat/theme-refresh`
(`lib/utils/app_theme.dart`, seed `#0E8F88`, Nunito). The Play screenshots were captured
before it: the raw captures under `store_listing/` show the violet app and the old home list,
and `scripts/compose_screenshots.py` draws the caption band on a Deep Purple gradient
described as "the app's seed colour" (`.llmwiki/StoreListing.md`). The store now shows an app
that no longer exists.

**Fix:** once the board entries of the visual refresh have landed too, re-capture the raw
screenshots (`scripts/capture_screenshots.sh`), move the caption gradient in
`compose_screenshots.py` to the teal, re-compose the ten locales, and publish with
`play_publish.py listing --graphics` (`release-android`).

**Acceptance:**
- `compose_screenshots.py` has no deep-purple colour; its gradient derives from `#0E8F88`.
- Every `store_listing/<locale>/screenshots/phone/` image shows the teal theme.
- `.llmwiki/StoreListing.md` no longer carries the Outdated block about the caption colour.
