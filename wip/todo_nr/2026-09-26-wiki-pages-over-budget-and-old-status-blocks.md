# Six wiki pages are over the size budget, and 75 status blocks were never folded

- **Noted:** 2026-09-26 — split out of [[2026-09-26-the-wiki-has-no-lint-script]] in refinement
- **Theme:** docs
- **Area:** docs
- **Blocks release:** no

`INDEX.md` caps a page at 400 lines so that a task loads only what it needs. Over it on
2026-09-26: `MobileApp.md` 1060, `Testing.md` 627, `Web.md` 489, `Release.md` 481, `Sync.md`
461, `SchemaV10.md` 439. And 75 `Status: Outdated` blocks sit under facts they contradict
(13 in `Release.md`, 11 in `Security.md`, 8 each in `Web.md` and `Sync.md`).

**Fix:** split the pages by sub-topic, most-read first — the order comes from
[[2026-09-26-no-measure-of-tokens-and-time-per-workflow]], which must land first; rewrite
each fact under an old status block and move its why to `## Decisions & History`. One pull
request per page or two, not one for all six.

**Acceptance:**
- The lint script reports no page over 400 lines and no status block older than the last release.
- Every split page's `INDEX.md` row and inbound `[[links]]` point at the new pages.
