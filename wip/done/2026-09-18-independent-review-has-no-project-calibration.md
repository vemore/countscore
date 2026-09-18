# The planned independent review has no project-specific instructions

**Status:** dropped (2026-09-18) — merged into [[2026-09-18-one-lane-for-every-change]] by chore/refine-2026-09-18.

- **Noted:** 2026-09-18 — comparing the project's SDLC with "Your SDLC is your context
  engineering" (Daniel Kravets, LeadDev, 2026-08-10)
- **Theme:** merge-safety
- **Area:** tooling
- **Blocks release:** no

Once [[2026-09-18-one-lane-for-every-change]] lands, lanes B and C run `/code-review high`
from a fresh agent with the command's generic defaults. In this project the wiki *is* the
agents' context, so a stale page misleads every later session, yet a generic review rates a
documentation mismatch as a nit. The article calibrates its reviewer for a team where agents
write most of the code.

**Fix:** a short section in `.llmwiki/ParallelDelivery.md` (or its own `Review.md` page if it
outgrows one), which the reviewer's prompt must load:

- verify each finding against the pull request's head before reporting it;
- a wiki, README or privacy document that the change makes false is at least Medium;
- read the page's `Decisions & History` before flagging something as redundant or odd;
- judge the tests against the entry's acceptance criteria, not against line coverage.
