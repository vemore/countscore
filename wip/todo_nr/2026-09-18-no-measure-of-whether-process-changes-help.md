# No measure says whether a change to the process made delivery better

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
