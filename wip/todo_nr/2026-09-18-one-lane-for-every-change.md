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

## Absorbed (2026-09-18, refinement)

This entry is now the only one on independent review. It carries:

- **From `2026-09-14-no-independent-review-before-merge`:** lane C's paths —
  `backend/app/routes/`, `backend/app/services/{ws_ticket,trusted_proxy,notify}.py`,
  `lib/services/sync/`, `lib/services/backend_client.dart`, `privacy_policy.md`,
  `PLAY_STORE_DATA_SAFETY.md`, `AndroidManifest.xml`. Evidence: #21 (+6.9 k lines, 64 files)
  was merged and deployed the day it opened, and six fix PRs (#22–#27) followed, among them
  a crash and security findings.
- **From `2026-09-16-plan-the-independent-review-before-writing`:** lane B's triggers (above),
  and the evidence for them: #75's planned review found a v4→v5 migration that made the
  database unopenable. Six CI checks were green, and there was no v4 fixture.
- **From `2026-09-18-independent-review-has-no-project-calibration`:** the reviewer's prompt,
  a section of `.llmwiki/ParallelDelivery.md` that the reviewer loads. It has four rules:
  - verify each finding against the PR head;
  - a wiki, README or privacy document the change makes false is at least Medium;
  - read `Decisions & History` before calling something redundant;
  - judge the tests against the acceptance criteria, not against coverage.
- **From `2026-09-18-wip-entries-carry-no-acceptance-criteria`** (the `**Acceptance:**`
  section itself landed in #90): criteria are mandatory for lanes B and C. `ship-parallel` §1
  shows them in the plan, and the §2 report maps each one to the test that covers it.

**Open question:** lane C's "explicit approval": an `AskUserQuestion` go-ahead in the
session, or a required CODEOWNERS review (which blocks a solo self-merge)? Should a planned
review also gate the agent's own completion (`SubagentStop`), or stay the orchestrator's step?
