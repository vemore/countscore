# The agent that implements a change also writes the tests that judge it

- **Noted:** 2026-09-18 — comparing the project's SDLC with "Your SDLC is your context
  engineering" (Daniel Kravets, LeadDev, 2026-08-10)
- **Theme:** merge-safety
- **Area:** tooling
- **Blocks release:** no

`ship-parallel` §2 rule 3 says "implement, with tests", and the `SubagentStop` hook refuses to
let the agent finish on a red pull request. Together they reward the cheapest way to green: a
missing case, a loosened assertion, a fixture that is never written — #75 had no v4 fixture.
Nothing separates writing the tests from writing the code, and nothing stops an agent looping
on the same failing check.

**Fix:** for lanes B and C only ([[2026-09-18-one-lane-for-every-change]]), so lane A stays fast:

- a **test-designer** subagent writes the tests from the entry's acceptance criteria
  ([[2026-09-18-wip-entries-carry-no-acceptance-criteria]]) before the implementation, without
  seeing it; the implementer may add tests, never weaken those;
- a **circuit breaker** in the agent prompt, for every lane: after three fix attempts on the
  same failing check, stop and report, classifying the failure as `TEST_ISSUE`, `IMPL_ISSUE`,
  `DOC_ISSUE` or `UNCLEAR` rather than trying a fourth time. The `SubagentStop` refusal then
  reads as "blocked, see report", which §2 already tells the orchestrator to read.
