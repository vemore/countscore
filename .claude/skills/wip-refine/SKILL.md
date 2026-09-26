---
name: wip-refine
description: Refine the CountScore wip/ backlog — check every open entry against the code, sort it into already fixed, obsolete, merge, needs detail, ready or promote, prioritise what is ready, and propose what moves from wip/todo_nr/ to wip/todo/; the user decides, then one pull request applies the decision. Use after a release ships, when wip/todo_nr/ passes 30 entries, or when the user asks what to work on next. Triggers: "refinement", "grooming", "backlog", "trier le backlog", "qu'est-ce qui passe en todo", "fais le tri dans wip", "what's next", "promote to todo", "obsolete entries".
---

# Refining the wip/ backlog

The point where an entry moves from `todo_nr/` to `todo/` is the **commitment point**: before
it, entries are options, cheap to write and cheap to drop; after it, they are the release in
progress. This skill prepares that decision and proposes it. **The user decides.** Nothing
moves until they answer, and what they decide lands in one pull request. Why it works this
way, and which practices it borrows from: `.llmwiki/ParallelDelivery.md` § Decisions & History.

**When:** after each release ships (the `release-android` checklist asks for it), when
`todo_nr/` passes 30 entries, or on request. Keep a pass short: it prepares a decision and does
not implement anything.

## 1. Mechanical signals

From the main checkout on a fresh `main` (`git fetch --prune origin && git merge --ff-only
origin/main`):

```bash
scripts/wip.sh refine all      # every open entry: age, idle days, flags; crowded themes
scripts/wip.sh check           # header fields, Status line in done/
```

| Flag | Means | Look at |
|---|---|---|
| `stale` | no commit on the entry for over 60 days | revalidate or drop it. An idea that matters will come back. |
| `dead-path:[…]` | a path in backticks no longer exists | refactored away (the evidence is stale), **or** a file the fix proposes to create. Read the sentence. |
| `links-closed:[…]` | links an entry already in `done/` | a dependency now met, or a problem the other entry already solved |
| `no-fix` / `no-acceptance` | the section is missing | a candidate for *needs detail* |
| `open-question` | a question waits on the user | ask it again, or keep it in *needs detail* |
| `crowded theme` | a theme with more than 4 entries | overlaps and supersessions: *merge* |
| `BLOCKS-RELEASE` | `Blocks release: yes` | always **promote**, whatever the rest |

## 2. Check each entry against the code

Read-only: is the problem still true today? Grep the files it names, read the lines, check
`git log --oneline -- <path>` since `Noted`, and look for a merged pull request that fixed it
without closing the entry. Every verdict carries a piece of **evidence**: a line, a commit or
a command output.

For more than 15 entries, split the work by theme across 2 or 3 `Explore` agents. Give each
agent its entries' paths and ask it for one line per entry: `still-true | fixed-by <sha/#PR> |
changed <what>`, plus the evidence. Never ask an agent to judge priority.

## 3. Sort into six bins, in this order

Hygiene before prioritisation: what goes away is cleared first, so it is never ranked.

1. **Already fixed.** The code no longer has the problem → `done/`, `Status: done`, naming the
   commit or pull request that closed it.
2. **Obsolete.** The feature was removed, a decision made it moot, or it went stale and
   nothing supports it any more → `done/`, `Status: dropped`, with the reason.
3. **Merge.** Several entries describe one problem, or one entry's fix replaces others (e.g.
   an entry saying "this replaces the two entries above"). The survivor absorbs the others'
   evidence. The others move to `done/` with `Status: dropped (date) — merged into [[survivor]]`.
4. **Needs detail.** Fails the definition of ready (§4). For each entry, give the **exact
   question** for the user or the evidence still to gather. "Needs more thought" is not an
   answer.
5. **Ready.** Passes §4.
6. **Promote.** Ready and within the top of the ranking (§5), up to the WIP limit.

## 4. Definition of ready

An entry is ready when all six hold:

1. **Still true.** The problem exists in today's code, and the evidence proves it.
2. **One pull request.** The `**Fix:**` is concrete and fits one reviewable pull request
   (about a day's work, one reason to revert). Anything bigger is split into several entries
   first.
3. **Testable.** An `**Acceptance:**` section gives 2 to 5 statements that can each be checked
   (`wip/README.md` § An entry). Draft them in the proposal; the user validates them.
4. **Unblocked.** No decision waits on the user, and no open entry has to land first.
5. **Themed.** The `Theme` reuses an existing tag (`scripts/wip.sh themes all`).
6. **Grounded, if the subject is common.** An entry on a problem others have already solved —
   not specific to CountScore (backups, deploy ordering, migrations, service workers, sync
   conflicts, CI metrics, …) — carries a `**State of the art:**` section (`wip/README.md`).
   Missing it on a common-subject entry is *needs detail*, not ready: the refinement pass
   runs the search itself (`WebSearch`/`WebFetch`) and writes the section — current practice,
   sources, the date consulted, and where the proposed fix departs from it and why — rather
   than asking the user for it.

Ready is required for **promotion**, not for writing an entry: a new entry stays twenty lines
of evidence and a fix.

## 5. Prioritise what is ready

No scoring formula: at this size, RICE or WSJF cost more than they decide, and "reach" cannot
be measured. Rank by:

1. **Cost-of-delay class.** *Expedite*: blocks the release, or a security, crash or data-loss
   problem. *Fixed date*: a store deadline or a policy date. *Standard*: user-visible value.
   *Intangible*: tooling, docs, debt. Higher classes come first.
2. Within a class, **value** (H/M/L) against **cost** (S/M/L): high value and small cost first.
   Two entries in one theme that would share a pull request are ranked together.

Give each ranked entry one line of reason. **WIP limit:** `wip/todo/` holds at most **12**
entries, about one `ship-parallel` run. Promote only to that limit. Anything over it stays
ready in `todo_nr/`.

## 6. Propose, then let the user decide

Present one table per bin: entry, verdict, evidence, and for *needs detail* the question. Then
ask one multi-select `AskUserQuestion` per non-empty bin, covering what to apply as proposed.
Ask the *needs detail* questions in the same round (at most 4 per call; group them). An entry
the user leaves unticked stays where it is.

## 7. Apply in one pull request

Work in a fresh worktree off `origin/main`, on branch `chore/refine-<YYYY-MM-DD>`:

- every move is a `git mv`, and the file name never changes (`wip/README.md` § Lifecycle);
- a closed or dropped entry gets its `**Status:**` line directly under the title;
- the answers to the *needs detail* questions and the approved acceptance criteria are written
  into the entries; a question the user leaves for later becomes an `**Open question:**` line
  (flagged `open-question` by `refine`), replaced by its answer at a later pass;
- `scripts/wip.sh check` is green, then commit, push, `gh pr create --base main`, `gh pr
  checks`, and squash-merge through `ship-parallel` §3. Only `wip/` changes, so there is
  nothing to deploy.

Report the counts per bin, the pull request URL and its check state, and what is now in
`wip/todo/`. From there, `ship-parallel` implements `wip/todo/`.

## When the tool itself fights you

A flag that fires on the wrong thing, a bin that does not fit, a limit that is always wrong:
record it as a `wip/` tooling entry, as `CLAUDE.md` says. Do not bend the pass around it.
