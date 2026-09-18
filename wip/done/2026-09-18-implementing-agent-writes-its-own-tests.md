# The agent that implements a change also writes the tests that judge it

**Status:** done (2026-09-18) — closed by chore/tooling-fixes. The `ship-parallel` §2 prompt carries a three-attempt circuit breaker reporting TEST_ISSUE / IMPL_ISSUE / DOC_ISSUE / UNCLEAR, §2 has the orchestrator's action per class, and `.llmwiki/ParallelDelivery.md` records why the test-designer subagent was dropped.

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

**Decided (2026-09-18, refinement):** split, and the test-designer subagent is dropped.
Acceptance criteria in the entry plus the independent review of lanes B and C
([[2026-09-18-one-lane-for-every-change]]) are judged enough to keep an agent from grading
its own work. What remains is the part that ships now, for every lane:

**Fix:** a **circuit breaker** in the `ship-parallel` §2 agent prompt: after three fix
attempts on the same failing check, stop and report, classifying the failure as `TEST_ISSUE`,
`IMPL_ISSUE`, `DOC_ISSUE` or `UNCLEAR` rather than trying a fourth time. The `SubagentStop`
refusal then reads as "blocked, see report", which §2 already tells the orchestrator to read.

**Acceptance:**
- The `ship-parallel` §2 agent prompt stops after three attempts on one failing check and reports with one of the four classes.
- §2 tells the orchestrator what to do with each class.
- `.llmwiki/ParallelDelivery.md` § Decisions & History records that the test-designer subagent was dropped, and why.
