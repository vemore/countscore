# ParallelDelivery

> Scope: how several changes are built at once and reach production — worktrees, one pull
> request per theme, serial squash merges, deploy after each merge, and `wip/` work tracking.
> Procedure: the `ship-parallel` skill. Related: [[Hooks]] · [[Deployment]] · [[Release]]
> Updated: 2026-09-16

## Facts

### The protection on `main` (read with `gh api repos/{owner}/{repo}/branches/main/protection`)

| Setting | Value | Consequence |
|---|---|---|
| `required_status_checks.strict` | `true` | A branch must contain the tip of `main` before it merges, so merges are **serial**: each merge makes every other open pull request stale |
| Required checks | All five CI jobs: `Backend — ruff, mypy, pytest`, `Backend image — build, non-root, locked`, `App — codegen, analyze, test, web build`, `Sync — two devices against a real backend`, `Android debug APK — fresh-clone build proof` | `image` and `sync` were made required on 2026-09-14: a merge is followed by a deploy of that very image, and `sync` is the only end-to-end proof of group sharing. No job may get a workflow-level `paths:` filter — a filtered workflow reports no status at all, and a required check that never reports leaves a doc-only pull request waiting forever. Scoping is done instead by the `scope` job and a job-level `if:` on each of the five: a job skipped by a conditional reports Success, so a doc-only pull request merges with the five checks satisfied ([[Testing]]) |
| `scope` is **not** a required check | deliberate | A failed `scope` already runs all five required jobs, so the merge stays fully gated; requiring it adds nothing there. The real risk is a `scope` that is green and wrong, which branch protection cannot see — the defences are `scripts/ci_scope_selftest.sh` and the catch-all rule. And a required `scope` that never starts (a workflow that does not parse) would hang every pull request forever, the exact failure this change exists to avoid |
| `required_linear_history` | `true` | Merge commits are refused on `main`: **squash** (or rebase) only. The project uses squash |
| `enforce_admins` | `false` | The owner's token can merge red pull requests (`--admin`) and push to `main`; `guard-bash.sh` refuses both instead |
| `allow_force_pushes` | `false` | On `main` only; feature branches are protected from force-pushes by the hook |
| `deleteBranchOnMerge` (repository) | `true` | A merged branch disappears from the remote; its local copy then reads `[gone]` and the hook refuses commits on it |

### Worktrees

- The **main checkout stays on `main`**, fast-forwarded, and never commits. Hooks are loaded
  from `${CLAUDE_PROJECT_DIR}/.claude/hooks` — that checkout's files, whatever branch the work
  is on — so the version of the rules in force is the main checkout's; and another session may
  be working next to you. Which repository each hook then judges: [[Hooks]].
- Work happens in worktrees: `git worktree add ../countscore-<topic> -b <type>/<topic>
  origin/main` by hand, or `.claude/worktrees/<name>` (branch `worktree-<name>`, gitignored)
  for an agent launched with `isolation: "worktree"`. The Agent tool removes its worktree on
  its own only when the agent changed nothing.
- `scripts/worktree_setup.sh` makes a worktree usable: `flutter pub get`, `build_runner`,
  `gen-l10n`, `uv sync --locked --extra dev`, and symlinks to the untracked
  `backend/scripts/deploy.env` and `android/key.properties` of the main checkout. While it
  runs it holds `<worktree>/.countscore-setup-in-progress` (pid, date, branch; gitignored,
  `.gitignore:137`) and removes it on the `ready:` line. A **failed** setup leaves the marker
  on purpose — a half-built worktree is exactly the one not to delete. Clearing a stale one
  is a manual `rm`, named in the script's `--help`.

### Cleaning up — `scripts/cleanup_local.sh`

Dry run by default, `--apply` to act. A local branch goes when it has no commit ahead of
`origin/main`, or when `gh pr list --head <branch> --state merged` finds a pull request and
GitHub's compare of its head against the local tip says `identical` or `behind`. A worktree
(never the main checkout) goes when `git status --porcelain` is empty and its branch goes, or
when it is detached on a commit in `origin/main`. Everything else is printed as `keep` with
the reason. `session-start.sh` points at it whenever a worktree or a `[gone]` branch exists.
Exercised offline by `scripts/hooks_selftest.sh` through a stubbed `gh`.

Two guards run **before** every other rule in the worktree loop
(`scripts/cleanup_local.sh:124-135`), and each keeps the worktree's **branch** as well as the
worktree — without that the branch loop deletes the branch out from under a live worktree:

| Guard | Evidence | Printed as |
|---|---|---|
| Setup in progress | `<worktree>/.countscore-setup-in-progress` exists | `keep … — setup in progress (.countscore-setup-in-progress)` |
| An agent may be working | `find <worktree> -newermt "-$CLEANUP_IDLE_MINUTES minutes" -print -quit` finds anything | `keep … — modified in the last N minutes (an agent may be working)` |

`CLEANUP_IDLE_MINUTES` defaults to `30`; `0` disables the second guard only — the marker is
always honoured. The self-test runs its first `--apply` with `CLEANUP_IDLE_MINUTES=0`, because
its sandbox worktrees are created seconds earlier and would otherwise all be kept.

Neither guard makes `--apply` safe to run while agents work: a worktree idle for more than the
window, with a branch that carries no commit yet, still looks abandoned. They cover the two
windows that cost work in practice — the five-minute setup, and an agent between commits.

### Work tracking, and what a merge deploys

Work tracking: `wip/README.md`. What a merge deploys, and how: `ship-parallel` §4 — the Play
Store is never part of the loop (`release-android`, on request).

## Decisions & History

- **Parallel delivery adopted (2026-09-14).** The user wanted several entries worked at once:
  one agent per theme, each in its own worktree, with Claude merging its own green pull
  requests and deploying the backend and the PWA after each merge, and fixes found in
  production going through a new pull request. Until then `CLAUDE.md` left merging to the
  user, and nothing described the whole chain.
- **`wip/` replaced `TODO.md` / `DONE.md` (2026-09-14).** Every pull request closed an item by
  cutting it from `TODO.md` and pasting it at the top of `DONE.md`, so any two pull requests
  conflicted on both files, systematically — the one conflict parallel work could not avoid.
  One file per entry, moved with `git mv` under a name that never changes, makes two branches
  collide only when they touch the same entry. No index file, for the same reason.
- **`todo_nr/` is the default for a new finding.** Findings arrive during unrelated work; if
  they all landed in the release in progress, its scope would grow with every session. Only
  what blocks the release (store policy, security, crash, data loss) goes to `todo/`.
- **The old `DONE.md` was archived, not split.** 39 entries, 1116 lines of reasoning:
  summarising them into short files risked losing exactly the *why* they were kept for. The
  user chose a frozen archive; a hook refuses edits to it.
- **Squash, and update by merging `main` in.** Linear history is required, so one of squash or
  rebase. Squash gives one commit per theme on `main` — revertable in one step, and what the
  deploy after each merge is keyed on. Updating a branch by rebasing would need a force-push,
  which would destroy the review history and, in a worktree an agent still holds, its
  commits; merging `main` into the branch avoids both, and the squash erases the merge commit.
- **Serial merges, deploy after each (2026-09-14).** `strict` makes merges serial anyway. The
  user chose to deploy after each merge rather than once per batch, so a regression in
  production points at a single pull request.
- **Cleanup became part of the loop (2026-09-14).** The first clean-up, done by hand the day
  the loop was adopted, found 20 local branches whose pull requests had merged and two stale
  worktrees. Proving each branch safe took three passes: `git cherry` flags every
  squash-merged branch as unmerged; comparing against the pull request head fails locally
  because heads updated on GitHub were never fetched; and `git merge-tree` against `main`
  reports "changes" that are only older versions of lines since rewritten. GitHub's compare of
  the merged head against the local tip is the one test that answers the real question —
  "did every local commit go into what merged?" — so the script uses it, and anything it
  cannot prove is kept.
- **The main checkout stays on `main`.** On 2026-09-14 this very change was built in a worktree
  while the main checkout sat on another session's merged branch. The hooks in force were that
  checkout's older copies: they judged its `[gone]` branch and refused the worktree's commits.
  Keeping the main checkout on a fast-forwarded `main` means the hooks are always the merged
  ones, and nothing ever commits there.
- **A worktree in setup became something the script can see (2026-09-16).** `--apply`, run
  from another session, deleted the `chore/flutter-deps` worktree *and* its branch while
  `worktree_setup.sh` was inside `build_runner`; the setup died on a `PathNotFoundException`
  under `.dart_tool/`. Everything the setup writes is gitignored, so `git status --porcelain`
  saw a perfectly clean worktree, and the branch had no commit yet — the two conditions the
  script treats as "abandoned". Both scripts' headers and this page already said "not while
  agents are working", and that is precisely what failed: an instruction the operator has to
  remember protects nothing. The fix is a handshake between the two scripts that own the two
  ends of it — the writer drops a marker, the reader honours it — plus a modification-time
  floor for an agent that is merely working rather than setting up. The marker is deliberately
  **not** cleared by a `trap`: a setup that crashed leaves the worktree half-built, which is
  the state that must survive. A branch-age heuristic was rejected: the branch in the incident
  was minutes old and still deleted, because age is not what the script reads.
- **A pull request touching `.claude/` merges last in its wave (2026-09-14).** The flip side of
  the previous point: fast-forwarding the main checkout after a merge that changes a hook
  changes the rules under agents still running. Such a pull request waits until every agent of
  its wave has reported. Recording the hooks' commit per session and warning on change was
  rejected as more process for the same result.
