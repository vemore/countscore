# The store screenshots show white avatar initials the app no longer draws

- **Noted:** 2026-09-19 — merging `fix/player-avatars-colours-keypad` (#152)
- **Theme:** store-listing
- **Area:** docs
- **Blocks release:** no

#152 picks each avatar's initial colour by WCAG contrast (`onPlayerColor`,
`lib/utils/player_colors.dart`), so most palette discs now carry a dark initial instead of a
white one, on the board, the keypad, the home hero, the Players screen and the rankings. It
also drew two-letter avatars on the keypad, the hero and the podium. The eight screenshots
retaken in all ten locales by #147 (`store_listing/<locale>/raw/`) show the old white,
partly one-letter avatars, so the Play listing no longer matches the app.

**Fix:** retake the raw captures on the demo data and recompose the ten locales, as #147 did
(`release-android`, store listing section). Best folded into the next retake, together with
[[2026-09-19-shared-raw-screenshot-set-is-stale]].

## Absorbed (2026-09-19, refinement 6)

From `2026-09-19-shared-raw-screenshot-set-is-stale`: `store_listing/assets/screenshots/phone/`
still holds the eight pre-refresh French captures (purple theme, no demo data, a
`04_game_history.png`). Nothing reads them except as the fallback for a locale with no `raw/`
set, and that fallback would compose a new locale from French purple captures whose stems
(`04_game_history`) do not match its captions (`04_podium`). `release-android` SKILL.md
(§ per-locale artwork) and `store_listing/ASSET_REQUIREMENTS.md` still describe that directory
as the screenshots. **Fix, same pull request:** delete the shared set and make
`compose_screenshots.py` require a locale `raw/` set (all ten have one); update its tests, the
skill, `ASSET_REQUIREMENTS.md` and `.llmwiki/StoreListing.md`.

Best done right before the next Play release.

**Acceptance:**
- Every `store_listing/<locale>/raw/` capture shows the two-letter avatars with the
  contrast-picked initial colour of the current build.
- No committed raw capture shows the old purple theme.
- A locale with captions and no `raw/` set is refused by the composer with a clear message.

**Promoted (2026-09-19):** by the user, for 1.3.0 — the listing should match the build it ships with.

**Status:** done (2026-09-19) — closed by docs/store-screenshots-retake. The eight raw captures retaken in all ten locales on the Pixel 9 Pro XL (profile build of main at 038a76a, demo data), showing the two-letter, contrast-picked avatars; all ten sets recomposed, `compose_screenshots.py --check` exits 0. The shared set is deleted and the composer refuses a locale with no `raw/` set.
