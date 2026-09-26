# The wiki has no lint script

**Status:** done (2026-09-26) — closed by feat/wiki-lint. `scripts/wiki_lint.sh` covers the
mechanical checks (dead backticked paths via the new shared `scripts/lib/dead_paths.sh`,
dangling `[[links]]`, the page-size and `Status: Outdated` findings, and `INDEX.md` date
drift), self-tested by `scripts/wiki_lint_selftest.sh` and wired into CI next to the other
self-tests; it is a report, not a gate, since the real wiki fails it today. `release-android`
§3b runs it. `SchemaV10` was renamed to `Schema` and every reference updated (15 files).
Splitting the six over-budget pages and folding the status blocks is
[[2026-09-26-wiki-pages-over-budget-and-old-status-blocks]].

- **Noted:** 2026-09-26 — comparing `.llmwiki/` with Karpathy's LLM Wiki pattern
- **Theme:** docs
- **Area:** tooling
- **Blocks release:** no

`.llmwiki/Documentation.md` now defines a wiki lint pass, run by hand in `release-android`
§3b. Its mechanical half is script work: `scripts/wip.sh` `refine` already finds dead
backticked paths, but only in `wip/` entries. What a first pass would find today:
- Six pages over the 400-line budget of `INDEX.md`: `MobileApp.md` 1060, `Testing.md` 627,
  `Web.md` 489, `Release.md` 481, `Sync.md` 461, `Schema.md` 439 — a task that needs one
  fact loads the whole page.
- `SchemaV10.md` describes schema v21; its name is referenced from 15 files.
- 75 `Status: Outdated` blocks (13 in `Release.md`, 11 in `Security.md`), never folded back.

**Fix:** a `wiki_lint.sh` in `scripts/`, reusing the dead-path pattern of `scripts/wip.sh`
`refine`, for the mechanical checks of Documentation "Wiki lint"; and rename `SchemaV10` to
`Schema`, the one finding cheap enough to clear in the same pull request. Splitting the pages
and folding the status blocks is
[[2026-09-26-wiki-pages-over-budget-and-old-status-blocks]].

**State of the art** (web search, 2026-09-26): docs-as-code checks links with `lychee` or
`markdown-link-check` and style with `markdownlint-cli2`, pinned in CI. None of them knows
`[[wiki links]]`, backticked repository paths, `file:line` or our `Updated:` dates, which are
most of the checks here, so the script stays ours; `lychee --offline` could cover plain
relative Markdown links. External links are left alone: a link checker run on every pull
request is an outbound-request primitive driven by repository content.
Sources: [lychee](https://lychee.cli.rs/),
[Microsoft playbook, Markdown reviews](https://microsoft.github.io/code-with-engineering-playbook/code-reviews/recipes/markdown/).

**Acceptance:**
- `wiki_lint.sh` lists each finding with its page and exits non-zero when there is one.
- It reports the six pages over budget and the old status blocks, and no dead reference, once `SchemaV10` is renamed.
- `SchemaV10` appears nowhere in the repository.
- `release-android` §3b runs it instead of the hand-made checks.
