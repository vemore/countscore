# The shared raw screenshot set is stale and no longer matches the captions

**Status:** dropped (2026-09-19) — merged into [[2026-09-19-store-screenshots-show-white-avatar-initials]] by chore/refine-2026-09-19-b.

- **Noted:** 2026-09-19 — while retaking the store screenshots (`feat/store-screenshots-retake`)
- **Theme:** store-listing
- **Area:** docs
- **Blocks release:** no

`store_listing/assets/screenshots/phone/` still holds the eight pre-refresh French captures
(purple theme, taken before the fictional demo data existed, and a `04_game_history.png`). Every store locale now composes
from its own `raw/` set, so nothing reads them — except as the fallback for a locale that has
no `raw/` set. A new store locale would therefore compose from French, purple captures, and
the composer would refuse it, because its captions (copied from an existing locale) name
`04_podium`, which the shared set lacks.

`release-android` SKILL.md (§ per-locale artwork) and `store_listing/ASSET_REQUIREMENTS.md`
still describe that directory as the screenshots.

**Fix:** either delete the shared set and make the composer require a locale `raw/` set
(simplest, since all ten have one), or replace it with the `en-US` raw set as a neutral
fallback. Update `compose_screenshots.py`'s fallback, its tests, the skill and
`.llmwiki/StoreListing.md` accordingly.

**Acceptance:**
- No committed raw capture shows the old purple theme.
- A locale with captions and no `raw/` set is either refused with a clear message or composed
  from a set whose stems match its captions.
