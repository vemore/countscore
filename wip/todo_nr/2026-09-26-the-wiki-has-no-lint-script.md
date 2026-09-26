# The wiki has no lint script, and six pages are over its size budget

- **Noted:** 2026-09-26 — comparing `.llmwiki/` with Karpathy's LLM Wiki pattern
- **Theme:** docs
- **Area:** tooling
- **Blocks release:** no

`.llmwiki/Documentation.md` now defines a wiki lint pass, run by hand in `release-android`
§3b. Its mechanical half is script work: `scripts/wip.sh` `refine` already finds dead
backticked paths, but only in `wip/` entries. What a first pass would find today:
- Six pages over the 400-line budget of `INDEX.md`: `MobileApp.md` 1060, `Testing.md` 627,
  `Web.md` 489, `Release.md` 481, `Sync.md` 461, `SchemaV10.md` 439 — a task that needs one
  fact loads the whole page.
- `SchemaV10.md` describes schema v21; its name is referenced from 15 files.
- 75 `Status: Outdated` blocks (13 in `Release.md`, 11 in `Security.md`), never folded back.

**Fix:** a `wiki_lint.sh` in `scripts/`, reusing the dead-path pattern of `scripts/wip.sh` `refine`,
for the mechanical checks of Documentation "Wiki lint"; then split the pages over budget —
in the order [[2026-09-26-no-measure-of-tokens-and-time-per-workflow]] shows they are read —
rename `SchemaV10` to `Schema`, and fold the old status blocks.

**Acceptance:**
- `wiki_lint.sh` lists each finding with its page and exits non-zero when there is one.
- It reports nothing on `main` once the split, the rename and the fold have landed.
- `release-android` §3b runs it instead of the hand-made checks.
