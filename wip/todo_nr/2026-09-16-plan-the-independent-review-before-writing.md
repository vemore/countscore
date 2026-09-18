# Work that will be large, complex or risky gets its independent review planned, not discovered

- **Noted:** 2026-09-16 — decided by the user after `feat/game-types-long-tail` (#75)
- **Theme:** merge-safety
- **Area:** tooling
- **Blocks release:** no

`ship-parallel` §3.1 checks the size of a pull request **after** an agent has written it: above
1 500 lines, the orchestrator asks the user before merging. That is a brake at the last
possible moment. It says nothing about planning, so the review that a large change needs is
improvised once the diff already exists — if anyone thinks of it at all.

**The evidence.** #75 (`feat/game-types-long-tail`, 1 827 lines excluding generated code) was
predicted to exceed the cap *at planning time*, and its independent review was written into
the plan for that reason. That review — a fresh agent running `/code-review high`, plus its
own verification pass with throwaway migration fixtures — found a blocking regression the
six green CI checks did not: `GameType.toMap()` began emitting `builtin_key`, and the
long-standing v4→v5 migration step passes the full map to `db.insert`, which builds its
column list from the map keys. On a device at schema v4 the insert throws and `openDatabase`
aborts — a permanently unopenable database. Six further findings came with it, two of them
sync rejections that are silent and terminal.

Every check was green. The suite had no v4 fixture, so nothing could have caught it. Had the
review not been planned, #75 would have been merged and deployed on its green checks.

The existing entry [[2026-09-14-no-independent-review-before-merge]] proposes a review gate
keyed on **sensitive paths**. This one is keyed on **shape**, and the two are complementary:
#75 would have tripped both, but a large refactor of pure UI code trips only this one.

**Fix:** make the review a planning decision rather than a merge-time discovery. In
`ship-parallel` §1, when a pull request is planned, judge it against three triggers and write
the answer into the plan presented to the user:

- it is expected to exceed **1 500 lines** excluding generated files;
- it changes something whose failures are **silent** — a migration, the sync contract, an
  Alembic revision, anything persisted or sent to another device;
- it does two things at once, or rewrites a call site that several unrelated features depend
  on (#75's `name`-as-join-key was five such sites).

Any one of them means an independent `/code-review high` from an agent that did not write the
change, run **before** the merge and reported to the user with the findings — not a size
number to approve. Record the triggers in `.llmwiki/ParallelDelivery.md` so they outlive the
skill's wording, and keep §3.1's post-hoc size check as the backstop for work whose size was
misjudged at planning time.

Worth deciding at the same time: whether a planned review should also gate the *agent's* own
completion, or stay the orchestrator's step. Today `SubagentStop` refuses to let an agent
finish on a red pull request; it knows nothing about whether the change was reviewed.
