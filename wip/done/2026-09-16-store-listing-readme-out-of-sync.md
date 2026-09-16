# store_listing/README.md states limits and sizes that are all wrong

**Status:** done (2026-09-16) — closed by docs/store-listing-aso. `store_listing/README.md`
was rewritten around what is actually committed: the ten-locale tree, the real Play limits
(30 / 80 / 4000 / 500), the `wc -m` check with the reason `wc -c` lies, the rules the copy
must obey, and the fact that `play_publish.py --listing` makes the repository win over the
Console. `store_listing/ASSET_REQUIREMENTS.md` (screenshot ratio and alpha) and `PUBLISHING.md`
§2 and §3 were corrected in the same change, and the `[YOUR_EMAIL_HERE]` placeholder left in
`en-US/release_notes_v1.0.0.txt` was replaced with `scribio.ai@gmail.com`.

- **Noted:** 2026-09-16 — while rewriting the listing copy
- **Theme:** store-listing
- **Area:** docs
- **Blocks release:** no

`store_listing/README.md` was written before the first submission and never corrected:

| Claim | Reality |
|---|---|
| "App name (50 chars max)", table row "App name · 50 chars · 26 chars" | Play's limit is **30**; `play_publish.py` refuses a longer file |
| "3,500+ character comprehensive description" | `en-US/full_description.txt` was **2 781** characters |
| Table row "Short description · 79 chars" | `en-US` was **78**, `fr-FR` **80** |
| Directory tree listing only `en-US/` and `fr-FR/` | out of date the moment more locales exist |
| "Status: Visual assets ⚠️ Need creation" | the icon, the feature graphic and 8 screenshots have been committed and published since 2026-09-15 |

`PUBLISHING.md` §2 already had the correct limit of 30, so the two documents disagreed with
each other.

**Fix:** rewrite the README around what is actually committed — the per-locale tree, the real
Play limits, and the fact that `play_publish.py --listing` is what publishes the text, so
editing a field in the Console without editing the file silently reverts at the next release.
