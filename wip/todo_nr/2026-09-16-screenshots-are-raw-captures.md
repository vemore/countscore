# The 8 store screenshots are raw captures in a ratio Play does not accept

- **Noted:** 2026-09-16 — while auditing the listing assets against `ASSET_REQUIREMENTS.md`
- **Theme:** store-listing
- **Area:** docs
- **Blocks release:** no

The eight PNGs in `store_listing/assets/screenshots/phone/` are straight `adb` captures from
`scripts/capture_screenshots.sh`. Measured on 2026-09-16 (`file` / PNG IHDR):

- **1080×2400**, ratio **2.222**;
- **colortype 6 (RGBA)** — an alpha channel.

Play asks phone screenshots for a ratio no wider than 16:9 (**1.778**) and an opaque 24-bit
image. `store_listing/ASSET_REQUIREMENTS.md` states the rule itself ("Aspect ratio: Max
dimension ≤ 2× min dimension", "Alpha: Not allowed") and the committed assets violate the
document that ships next to them.

They are also weak as marketing: no text overlay, so a visitor scrolling the carousel has to
read the UI to know what the app does; not localized, so the ten listing locales all get
French/English UI; and pale enough to be unreadable at thumbnail size, which is where the
decision to tap is actually made.

**Fix:** (lot 2, after the copy lands) a `scripts/compose_screenshots.py` — Pillow, PEP 723
inline dependencies, run with `uv run --script` like the other release scripts — that reads
the raw captures and writes **1080×1920 RGB** compositions with a localized title band above
the screen, one output set per store locale. Then re-publish with
`play_publish.py publish --graphics`. Needs the per-locale caption strings, so it follows the
listing copy rather than preceding it.

**Decided (2026-09-18, refinement):** 1080×1920 RGB, as proposed. Claude drafts the eight
French captions from the store listing copy, the user validates them in the pull request,
and the nine other locales are translated from them.

**Acceptance:**
- `scripts/compose_screenshots.py` writes 1080×1920 opaque RGB PNGs, one set per store locale.
- The eight French captions are validated by the user in the pull request, then translated.
- `play_publish.py validate` accepts the new graphics.
