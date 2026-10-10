# Nobody has measured yet whether the ten store locales of 2026-10-04 brought installs

- **Noted:** 2026-10-10 — while reading the Play Console against the 2026-09-16 baseline
- **Theme:** store-listing
- **Area:** docs
- **Blocks release:** no

The 2026-10-10 measure (`.llmwiki/StoreListing.md` §Measured again on 2026-10-10) shows the
listing gain coming only from France and Belgium. The ten locales published with 1.6.0 (10)
— `id` `tr-TR` `it-IT` `ko-KR` `vi` `th` `pl-PL` `bn-BD` `ur` `nl-NL` — were six days old and
the listing data stopped at 10-04/05, so their effect could not be seen.

**Fix:** from 2026-11-01, read the Console (Statistics → installed audience by country,
Store listings → visitors and install clicks, 28 days) and record a third column in the
StoreListing table, with installs per country for the twenty store locales.

**Acceptance:**
- `.llmwiki/StoreListing.md` has a dated measure taken on or after 2026-11-01.
- It lists installed audience by country, and says whether any of the ten new locales' countries appears.
- This entry is moved to `wip/done/` with `**Status:** done`.
