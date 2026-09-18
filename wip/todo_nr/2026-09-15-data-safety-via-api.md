# The Data Safety form is still filled in by hand, though the Play API can set it

- **Noted:** 2026-09-15 — while adding `play_publish.py` (feat/play-publish-api)
- **Theme:** release-automation
- **Area:** tooling
- **Blocks release:** no

`PLAY_STORE_DATA_SAFETY.md` is the source of truth for the Data Safety declaration, but the
Console form is walked question by question by the user or a browser agent
(`release-android` §9), so the two can drift. The Publishing API has
`applications.dataSafety` (androidpublisher v3), which takes the declaration as the CSV the
Console exports (Policy → App content → Data safety → Export to CSV).

It was left out of `play_publish.py` on purpose: the call **overwrites the whole
declaration** in one request, is not part of an edit (no validate-then-commit), and the
resulting change still goes through Google's review.

**Fix:** export the current form once, commit the CSV next to `PLAY_STORE_DATA_SAFETY.md`
(e.g. `store_listing/data_safety.csv`), and add `play_publish.py data-safety` that prints a
diff against what the Console exported and sends the CSV only with an explicit `--commit`.
Keep the CSV and `PLAY_STORE_DATA_SAFETY.md` in the `.llmwiki/Documentation.md` rule so a new
data flow updates both.

**Open question:** Accept an API call that overwrites the whole Data Safety declaration, gated behind `--commit`? And who exports the first CSV from the Console?
