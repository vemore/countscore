# A wip/ entry says what to fix, never how we will know it is fixed

**Partly done (2026-09-18)** — chore/wip-refine added the `**Acceptance:**` section to the entry
format and made it a condition of promotion to `todo/` (`wip-refine` §4). What is left: making
it mandatory by lane, and mapping each criterion to its test in `ship-parallel` §1 and §2.

- **Noted:** 2026-09-18 — comparing the project's SDLC with "Your SDLC is your context
  engineering" (Daniel Kravets, LeadDev, 2026-08-10)
- **Theme:** merge-safety
- **Area:** tooling
- **Blocks release:** no

The entry format (`wip/README.md` § An entry) is the problem and a `**Fix:**`, twenty lines or
so. Nothing states the acceptance criteria, so the implementing agent decides alone what
"done" means, and the tests it writes prove what it built rather than what was asked. The
article's central finding: almost every critical issue comes from the specification and the
planning, not from the code.

**The evidence.** 29 of the 112 commits on `main` since 2026-09-09 are `fix:`. #75's blocking
regression (the v4→v5 migration inserting `builtin_key`, a database that no longer opens) went
through six green checks because no criterion asked for "migrates from every schema version"
(`wip/todo/2026-09-16-plan-the-independent-review-before-writing.md`).

**Fix:** add an optional `**Acceptance:**` section to the entry format — a few testable
statements, not a design — mandatory for work in lane B or C
([[2026-09-18-one-lane-for-every-change]]). `ship-parallel` §1 shows the criteria in the plan
the user approves: reading five lines of criteria is cheaper than reading 1 800 lines of diff,
and it is where the user's review time buys the most. The agent's report (§2 rule 8) maps each
criterion to the test that covers it.
