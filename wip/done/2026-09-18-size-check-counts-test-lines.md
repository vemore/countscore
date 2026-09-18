# The 1 500-line merge check counts test code against the pull request

**Status:** done (2026-09-18) — closed by chore/agent-scope-and-size-check. The `ship-parallel`
§3.1 size filter also leaves out `^test/`, `^integration_test/` and `^backend/tests/`, and
`.llmwiki/ParallelDelivery.md` says why. [[2026-09-18-one-lane-for-every-change]] has not
landed, so there is no lane-B trigger to change yet.

- **Noted:** 2026-09-18 — comparing the project's SDLC with "Your SDLC is your context
  engineering" (Daniel Kravets, LeadDev, 2026-08-10)
- **Theme:** merge-safety
- **Area:** tooling
- **Blocks release:** no

The `jq` filter in `.claude/skills/ship-parallel/SKILL.md` §3.1 leaves out `*.g.dart`, the
generated localizations, the lock files and the two web binaries, but not `test/`,
`integration_test/` or `backend/tests/`. A pull request that tests thoroughly gets closer to
the cap that makes the orchestrator stop and ask, so the check pushes against the tests the
project most wants. The article excludes test files from its size limits for that reason.

**Fix:** add `^test/`, `^integration_test/` and `^backend/tests/` to the regex, and say why in
`.llmwiki/ParallelDelivery.md`. A one-line change; if [[2026-09-18-one-lane-for-every-change]]
lands first, apply the same exclusion to its lane-B size trigger.

**Acceptance:**
- The `ship-parallel` §3.1 size regex also excludes `^test/`, `^integration_test/` and `^backend/tests/`.
- `.llmwiki/ParallelDelivery.md` says why.
