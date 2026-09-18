# Every change takes the same path to production, whatever its risk

- **Noted:** 2026-09-18 — comparing the project's SDLC with "Your SDLC is your context
  engineering" (Daniel Kravets, LeadDev, 2026-08-10)
- **Theme:** merge-safety
- **Area:** tooling
- **Blocks release:** no

`ship-parallel` runs a one-line wording fix and a sync-contract change through the same loop:
one agent writes, the orchestrator reads the diff, merges and deploys. The only brake is the
1 500-line check at §3.1, applied after the code exists. Two open entries each propose half of
a risk-based path: [[2026-09-14-no-independent-review-before-merge]] (keyed on sensitive paths)
and [[2026-09-16-plan-the-independent-review-before-writing]] (keyed on the shape of the
change). The article names the whole of it: execution lanes decided at planning time.

**Fix:** one rule, recorded in `.llmwiki/ParallelDelivery.md` and applied in `ship-parallel`
§1 (lane chosen and shown in the plan) and §3 (what the lane requires before merging):

- **A — standard.** Today's loop.
- **B — planned.** Over 1 500 lines excluding generated files and tests, a failure that is
  silent (migration, sync contract, Alembic, anything persisted or sent to another device), or
  a call site several features depend on. Acceptance criteria in the entry
  ([[2026-09-18-wip-entries-carry-no-acceptance-criteria]]), then `/code-review high` from an
  agent that did not write the change, findings reported to the user before the merge.
- **C — sensitive paths.** The path list of the 2026-09-14 entry. Lane B, plus the user's
  explicit approval of the merge.
- **D — experiment.** A branch with `noPullRequest`, never merged as is.

This **replaces** the two entries above rather than adding to them: the pull request that
implements it closes all three, and §3.1's size check stays only as the backstop for a lane
misjudged at planning time.
