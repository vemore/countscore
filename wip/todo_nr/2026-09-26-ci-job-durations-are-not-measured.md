# The CI job durations are not measured

- **Noted:** 2026-09-26 — building `scripts/agent_metrics.py`
  ([[2026-09-26-no-measure-of-tokens-and-time-per-workflow]])
- **Theme:** process-evals
- **Area:** tooling
- **Blocks release:** no

The closed entry asked for the CI job durations next to the transcript figures; the scripts
left them out. The transcripts show the wait they cause — `gh pr checks --watch` is 16.7 % of
the agents' tool time since 2026-09-01 (`.llmwiki/ParallelDelivery.md` § Measuring delivery)
— but not which job makes it: `gh run list` has no job list, and `gh run view --json jobs` is
one API call per run (377 pull-request runs to date).

**Fix:** a `--ci` option to `scripts/delivery_metrics.sh`, or its own line in the report: for
the runs of the merged pull requests in the window, the median and p90 duration of each job
of `ci.yml` (`scope`, `backend`, `app`, `android`, `image`, `sync`), cached under the
scratch directory so a second run makes no call. Then name the job that dominates the wait.

**Acceptance:**
- The report prints the median and p90 duration per CI job for the window.
- A second run in the same window makes no GitHub API call per run.
- The baseline in `.llmwiki/ParallelDelivery.md` § Measuring delivery gains the job line.
