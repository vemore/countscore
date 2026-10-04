# The Play listing has no page for the ten new app languages

- **Noted:** 2026-10-04 — the user asked for ten more languages, store listing included
- **Theme:** store-listing
- **Area:** docs
- **Blocks release:** no

Adding a language to `lib/l10n/` does not create the listing that makes it findable in that
market (`.llmwiki/StoreListing.md`). The Play locales for the ten languages of
`2026-10-04-app-and-backend-speak-ten-more-languages.md`: `id` · `tr-TR` · `it-IT` · `ko-KR` ·
`vi` · `th` · `pl-PL` · `bn-BD` · `ur` · `nl-NL`.

**Fix:** a `store_listing/<locale>/` directory each with `title.txt` (≤ 30, the market's head
term first), `short_description.txt` (≤ 80), `full_description.txt` (≤ 4000),
`screenshot_captions.txt` and `video.txt`, translated from `en-US` and `fr-FR` under the copy
rules of `StoreListing.md` (never "our server", no backend URL, no third-party game name in the
title or captions, no keyword stuffing). `scripts/compose_screenshots.py` gets the fonts and the
shaping, RTL and no-space sets for `ko-KR`, `th`, `bn-BD` and `ur`. Nothing is published
(`release-android`, on request).

**Acceptance:**
- Every `title.txt`, `short_description.txt` and `full_description.txt` is within 30 / 80 / 4000
  characters (`wc -m`), and `play_publish.py` accepts the ten new locales (`validate` dry run,
  its tests).
- Each new `screenshot_captions.txt` has the eight stems and each caption fits two lines at 48 px
  in `compose_screenshots.py` with its font.
- `scripts/test_compose_screenshots.py` covers the four new scripts.
