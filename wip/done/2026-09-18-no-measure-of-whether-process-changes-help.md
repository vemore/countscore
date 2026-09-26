# No measure says whether a change to the process made delivery better

**Status:** done (2026-09-26) — closed by feat/delivery-and-agent-metrics. `scripts/delivery_metrics.sh [since [until]]` prints the `fix:` share, the rework rate, deployments and change failure rate, first-run-green, size per change and `wip/` ages — 30/118 `fix:` for 2026-09-09..2026-09-18, the hand count of 29/112 having been taken that morning; the baseline is in `.llmwiki/ParallelDelivery.md` § Measuring delivery, and `ship-parallel` §6 prints it.

- **Noted:** 2026-09-18 — comparing the project's SDLC with Anthropic's "The AI-native SDLC
  playbook" (claude.com/blog/the-ai-native-sdlc-playbook)
- **Theme:** process-evals
- **Area:** tooling
- **Blocks release:** no

The process is calibrated in flight — tooling entries, pruning pass, new rules after each
incident — but on anecdote. The one figure used so far, 29 `fix:` commits out of 112 between
2026-09-09 and 2026-09-18, was counted by hand once. Nothing will tell whether the lanes, the
acceptance criteria or a pruned hook ([[2026-09-18-one-lane-for-every-change]]) reduced rework
or only added steps. The playbook attaches leading and lagging indicators to every stage.

**Fix:** a `scripts/delivery_metrics.sh [since]` computed from git and `gh` only, no new
tracking: share of `fix:` commits; pull requests followed within 48 h by a fix touching the
same files; share of pull requests green on their first CI run; merged size distribution
(generated files and tests excluded); open `wip/` entries by folder and age. Print it in the
`ship-parallel` §6 report and record a baseline in `.llmwiki/ParallelDelivery.md`, so the
`release-android` §3b pruning pass can compare before and after. Keep it to the few numbers
the pass will actually read.

**State of the art** (web search, 2026-09-26): DORA added a fifth metric in 2025, **rework
rate** — the share of deployments that fix a problem users hit — next to change failure
rate, because AI-assisted teams ship more and break more (2025 DORA report: +98 % merged
pull requests per developer, +242.7 % incidents per pull request). The "fix within 48 h
touching the same files" above is our rework rate; name it so, and report deployment
frequency and change failure rate from the same git and `gh` data.
Sources: [DX, DORA metrics](https://getdx.com/blog/dora-metrics/),
[Plandek, DORA in the age of AI](https://plandek.com/blog/how-to-measure-dora-metrics-in-the-age-of-ai-2026).

**Acceptance:**
- `scripts/delivery_metrics.sh [since]` prints the `fix:` share, fixes within 48 h touching the same files, the first-run-green share, the size distribution (excluding generated files and tests), and entry ages per `wip/` folder.
- It reproduces about 29/112 `fix:` commits for 2026-09-09..2026-09-18.
- The baseline is recorded in `.llmwiki/ParallelDelivery.md`.
