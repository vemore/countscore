# The 1 500-line merge cap counts deletions, documentation and translations

**Status:** done (2026-09-20) — closed by docs/execution-lanes. `ship-parallel` §3.1 now
counts the added or modified lines of code from `gh pr diff`, dropping pure deletions,
`*.md`, `wip/`, `*.arb` and `app_localizations*.dart` on top of the existing exclusions, and
says why `gh pr view --json files` cannot measure this. The 1 500 threshold is unchanged.
Re-measured: #199 counts 279 instead of 1 590, #192 counts 50, a docs-only pull request 0.
`.llmwiki/ParallelDelivery.md` § Decisions records the decision and the #199 numbers.

- **Noted:** 2026-09-20 — measuring `docs/brand-guides` (#199) before merging it
- **Theme:** merge-safety
- **Area:** tooling
- **Blocks release:** no

`ship-parallel` §3.1 sums `additions + deletions` over every file the pull request touches,
minus generated, lock, binary and test paths. It therefore charges a pull request for lines it
*removes*, for prose, and for translated strings — none of which is production code one review
has to hold in its head.

Evidence: #199 (`docs/brand-guides`) measured **1 590 lines** by that formula and so needed the
user's go-ahead, although it contained no application code beyond a ten-line comment. Of those
1 590 lines, **1 026 were deletions** — the two dead purple design guides `ICON_DESIGN_GUIDE.md`
(612) and `COLOR_THEME_GUIDE.md` (414) — and 269 were a new Pillow script. The deletions were
the point: the entry `2026-09-20-the-brand-docs-still-describe-the-abandoned-purple` had asked
for them. The cap taxed exactly the housekeeping the project wants to encourage, and it taxes
translation the same way — a string added in ten languages reads as ten times the risk.

**Fix:** keep the **1 500** threshold; change what is counted. The count becomes the **added or
modified lines of code**:

- a **pure deletion costs nothing** — a removed line is not code a review has to hold;
- **documentation does not count** — `*.md` anywhere, `.llmwiki/`, `wip/`, `README.md`, the
  skills;
- **translations do not count** — `lib/l10n/*.arb` and the generated `app_localizations*.dart`;
- everything already excluded stays excluded: `*.g.dart`, `pubspec.lock`, `backend/uv.lock`,
  `web/sqlite3.wasm`, `web/drift_worker.js`, `test/`, `integration_test/`, `backend/tests/`.

`gh pr view --json files` cannot express this: it knows only `additions` and `deletions` per
path, and cannot tell a modified line from an added one. The count must be measured on the diff
itself — the `+` lines that are not `+++`, in the paths that are kept — since a modified line
appears there as one `-` and one `+`.

**Acceptance:**
- `ship-parallel` §3.1 counts added-or-modified lines of code from the diff, excluding pure
  deletions, `*.md`, `wip/`, `*.arb` and `app_localizations*.dart` on top of the existing
  exclusions, and does not claim a precision `--json files` cannot give.
- A pull request shaped like #199 (1 026 deleted documentation lines, a new script, no app
  code) measures well under 1 500.
- `.llmwiki/ParallelDelivery.md` records the decision, the #199 numbers, and that the 1 500
  threshold itself is unchanged.
