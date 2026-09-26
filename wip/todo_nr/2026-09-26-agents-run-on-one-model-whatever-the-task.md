# Agents run on the session's model whatever the task's complexity

- **Noted:** 2026-09-26 — the user asked that complex tasks go to Opus at high effort and
  clear, simple ones to Sonnet
- **Theme:** tooling
- **Area:** tooling
- **Blocks release:** no

`ship-parallel` §1 plans each pull request — theme, lane A–D, files, wave — but says nothing
of the model: every implementing agent inherits the orchestrator's model and effort. A string
rename and a sync-contract change cost the same per token and get the same reasoning budget.
The one routing rule in force is outside the repository: bulk translations go to Haiku (user
memory). The lanes rate *risk to production*, not *difficulty*: a lane-A change can still be
hard to get right.

The `Agent` tool takes a `model` per call, but effort comes only from an agent definition's
frontmatter (.claude/agents/*.md), so "Opus, effort high" needs a project agent definition.

**Fix:**
- At planning (`ship-parallel` §1, next to the lane), rate each pull request **complex** or
  **simple**, and name the rating in the plan the user approves. Complex: a design choice is
  open, several subsystems move together, the root cause is unknown, or lane B/C. Simple: the
  entry's fix is explicit and local, its acceptance is mechanical. In doubt, complex.
- Two project agents in .claude/agents/: implementer-complex.md (`model: opus`, effort high)
  and implementer-simple.md (`model: sonnet`); §2 launches the one the rating
  picks. Bulk translation stays on Haiku.
- A rule in `.llmwiki/ParallelDelivery.md` (why, and the criteria); one line in `CLAUDE.md`
  only if the budget allows.
- Check the split against [[2026-09-26-no-measure-of-tokens-and-time-per-workflow]]: cost and
  rework per rating.

**Acceptance:**
- The `ship-parallel` §1 plan names a rating for each pull request, with the criteria above.
- .claude/agents/ holds the two definitions, and §2 launches by rating.
- `.llmwiki/ParallelDelivery.md` records the rule and its Decisions & History line.
