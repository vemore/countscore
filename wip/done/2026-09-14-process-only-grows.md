# The process only ever grows: nothing prunes a rule, a hook or a wiki page

**Status:** done (2026-09-14) — closed by docs/process-pruning. `CLAUDE.md` capped at 120 lines and cut from 204 (details moved to the new `.llmwiki/Documentation.md`, `wip/README.md`, `Hooks.md`, `ParallelDelivery.md`); a pruning pass added as `release-android` §3b (decision in `Release.md`); `wip/README.md` now says a tooling entry may propose a removal and prefers replacing to adding.

- **Noted:** 2026-09-14 — while reviewing the two weeks of work since 2026-09-09
- **Theme:** process-pruning
- **Area:** tooling
- **Blocks release:** no

Between 2026-09-09 and 2026-09-14 about 40 % of the lines written were process rather than
product: `CLAUDE.md` (204 lines), `.llmwiki/` (~2 400), skills (~1 100), hooks (~1 100, a
523-line shell parser among them) and 110 hook self-test cases. That tooling has its own
defects — the pull-request hook blocking forever after a merge (#6), the commit hook ignoring
worktrees, 20 stale local branches (#34) — and every agent pays for reading it on each launch.
The rule "tooling that fights you is a `wip/` entry" only ever adds: every incident became a
rule, and no rule has been removed.

**Fix:** a counterweight. A size budget for `CLAUDE.md` (move anything past it to the wiki
page that owns it); a periodic pass — say before each Play Store release — that lists each
hook refusal and `CLAUDE.md` rule, asks whether it fired or was needed since the last pass,
and deletes or merges the ones that were not; and a line in `wip/README.md` saying a
tooling entry may propose removing something, not only adding.
