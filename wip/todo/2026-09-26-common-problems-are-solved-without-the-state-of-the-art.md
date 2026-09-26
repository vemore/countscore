# Entries on common problems are designed without looking at the state of the art

- **Noted:** 2026-09-26 — the user asked that an entry on a common subject get a web search
  on the state of the art and current best practice
- **Theme:** tooling
- **Area:** tooling
- **Blocks release:** no

Many entries are problems others have solved before: backups, deploy ordering, migrations,
service workers, sync conflicts, CI metrics. Their **Fix** is written from the codebase alone.
When a standard was checked, it happened by accident, and it paid: the backend deploy gaps
(#224) came from a comparison against standard practice, the process-evals entries from
Anthropic's SDLC playbook, the wiki conventions (#226) from Karpathy's LLM Wiki. Nothing asks
for it: the `wip/README.md` template and the definition of ready (`wip-refine` §4) have no
such step.

**Fix:**
- `wip/README.md`: an entry whose subject is common, not specific to CountScore, carries a
  `**State of the art:**` section — what current practice is, from a web search, with the
  sources and the date consulted, and where the proposed fix departs from it and why.
- `wip-refine` §4: a common-subject entry without that section is *needs detail*, not ready;
  the refinement pass runs the search itself (`WebSearch`/`WebFetch`) and writes the section.
- `scripts/wip.sh` `refine`: no flag — "common" is judgement, not a pattern.

**Acceptance:**
- The `wip/README.md` template shows the section and says when it applies.
- `wip-refine` §4 lists it in the definition of ready.
- A refinement pass on the open `backend-hardening` / `deploy-safety` entries adds the section with dated sources.
