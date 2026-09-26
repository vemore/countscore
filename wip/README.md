# wip — work tracking

One file per piece of work, so that parallel pull requests never conflict on a shared list.

| Folder | Holds |
|---|---|
| `todo/` | Open work for the release in progress (`version:` in `pubspec.yaml`) |
| `todo_nr/` | Open work for the next release |
| `done/` | Closed work, and `ARCHIVE-2026-09.md` — the old `DONE.md`, frozen |
| `assets/<entry-slug>/` | Images an entry points at, such as the mock-ups that are its implementation target. The folder keeps the entry's slug and stays put when the entry moves |

`scripts/wip.sh` is the index: `list [todo|todo_nr|done|all]`, `themes`, `check`, `refine`. There is
no index file on purpose — it would be the one shared file again.

## An entry

`<folder>/YYYY-MM-DD-<slug>.md`, dated the day the problem was noted. Short: the evidence and
the fix, twenty lines or so.

```markdown
# <What is wrong, as a statement>

- **Noted:** 2026-09-14 — <while doing what>
- **Theme:** <one tag, e.g. store-listing, backend-hardening, hooks>
- **Area:** app | backend | web | android | tooling | docs
- **Blocks release:** yes — <why> | no

<The problem, with file paths and evidence.>

**Fix:** <the proposed change.>

**State of the art:** <only when the subject is common — not specific to CountScore, e.g.
backups, deploy ordering, migrations, service workers, sync conflicts, CI metrics. A web
search for current practice, with sources and the date consulted, and where the proposed
fix departs from it and why. Skip this section for an entry that is purely about this
codebase.>

**Acceptance:** <optional when written; required to be promoted to todo/ —
2 to 5 statements a test or a command can check.>

**Open question:** <what the user must decide before the entry is ready; a refinement
pass writes it, and the answer replaces it.>
```

The three bold run-ins are a guide, not a schema: `wip.sh refine` finds each section as a
`##` heading too, with or without the colon, in any case, and in French (`Fix proposé`,
`Correctif`, `Question ouverte`).

An entry whose target is visual links its images from `assets/<its slug>/` with relative links
(`../assets/<slug>/<image>.png`), so the target lives in the repository and not only behind a
link to an external page.

`Theme` is what groups entries into one pull request: reuse an existing tag
(`scripts/wip.sh themes all`) before inventing one.

## Where a new entry goes

A problem a task surfaces but was not asked to fix is neither fixed inline nor dropped: it
becomes an entry with enough context to act on later, and the task carries on.
`todo_nr/` by default. `todo/` only when it blocks the release in progress: a store policy
violation, a security flaw, a crash, data loss. The user promotes the rest, from the proposal
of a refinement pass (below).

## Tooling entries

A skill, a hook, a slash command, a wiki procedure or a part of `CLAUDE.md` that had to be
worked around — steps that no longer match the code, a gate that fires on the wrong thing, a
rule that forced a detour, something done by hand twice that no skill covers — is the same
class of finding as a bug in `lib/`. The entry names the tool, what it actually made you do,
and the change proposed.

- **The change may be a removal.** A rule, a hook refusal or a wiki page that costs more than
  it catches is a valid finding; prefer replacing a rule to adding one next to it. The
  periodic pass that looks for these is `release-android` §3b.
- **A one-line correction the current task already proves wrong** — a renamed file in a
  skill, a dead command — is fixed inline and mentioned. Anything that changes what a tool
  *does* is a proposal, not a detour of its own.

## Lifecycle

- **Moving** between folders is `git mv` — the file name never changes, so two branches
  touching different entries never conflict.
- **Closing** happens in the pull request that fixes it: `git mv wip/todo/X.md wip/done/X.md`,
  then a line under the title:
  `**Status:** done (YYYY-MM-DD) — closed by <branch or #PR>. <What closed it, in one or two sentences.>`
- **Partly done** stays open. Say what landed, and keep only what is left.
- **Dropping** an entry that is obsolete, or merged into another, is a move to `done/` too, with
  `**Status:** dropped (YYYY-MM-DD) — <why, or: merged into [[survivor]]>`. `done/` keeps what
  was dropped next to what shipped, so an idea that comes back finds its history.
- **Never delete an entry, and never edit one another pull request owns.**

## Refinement

Moving an entry from `todo_nr/` to `todo/` is the commitment point, and `todo/` holds at most
12 entries. The `wip-refine` skill prepares that decision: it checks each open entry against
the code, sorts it (already fixed, obsolete, merge, needs detail, ready, promote), and ranks
what is ready. The user decides, and one pull request applies the decision. It runs after each
release ships, when `todo_nr/` passes 30 entries, or on request.

A commit hook refuses a root `TODO.md` or `DONE.md` next to `wip/`, and any edit to the
archive (`.llmwiki/Hooks.md`).
