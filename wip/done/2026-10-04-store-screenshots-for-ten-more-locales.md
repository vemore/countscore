# The ten new locales have no Play screenshots of their own

**Status:** done (2026-10-04) — closed by docs/play-screenshots-ten-more-locales. 80 captures taken over adb on the Pixel (profile build, demo database), read screen by screen, composed to 1080×1920; `compose_screenshots.py --check` exits 0 over twenty locales. Not published. Two defects found on the way: the statistics headers of `id` and `vi` collided (fixed in #fix/stats-header-id-vi), and negative scores read `25-` in Urdu (new entry).

- **Noted:** 2026-10-04 — the user asked for ten more languages, store listing included
- **Theme:** store-listing
- **Area:** android
- **Blocks release:** no

Each locale's carousel shows that locale's own UI (`.llmwiki/StoreListing.md`; the publisher
refuses a locale without `screenshots/phone/`). The ten locales of
`2026-10-04-play-listing-in-ten-more-locales.md` need eight composed screenshots each.
**Blocked** on the app shipping the languages (PR of
`2026-10-04-app-and-backend-speak-ten-more-languages.md`) and on the Pixel: the user gives the
wireless-debugging port at the time, the address is static.

**Fix:** for each locale `scripts/capture_screenshots.sh <locale>` on a profile build of `main`
with the demo database, then `uv run --script scripts/compose_screenshots.py`. Uninstalling the
Play app for the profile APK needs the user's go-ahead (its data goes).

**Acceptance:**
- `compose_screenshots.py --check` exits 0 with the twenty locales.
- Each new `screenshots/phone/` holds exactly the eight composed 1080×1920 opaque PNGs.
