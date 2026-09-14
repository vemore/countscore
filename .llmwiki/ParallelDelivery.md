# ParallelDelivery

> Scope: how several changes are built at once and reach production — worktrees, one pull
> request per theme, serial squash merges, deploy after each merge, and `wip/` work tracking.
> Procedure: the `ship-parallel` skill. Related: [[Hooks]] · [[Deployment]] · [[Release]]
> Updated: 2026-09-14

## Facts

### The protection on `main` (read with `gh api repos/{owner}/{repo}/branches/main/protection`)

| Setting | Value | Consequence |
|---|---|---|
| `required_status_checks.strict` | `true` | A branch must contain the tip of `main` before it merges, so merges are **serial**: each merge makes every other open pull request stale |
| Required checks | All five CI jobs: `Backend — ruff, mypy, pytest`, `Backend image — build, non-root, locked`, `App — codegen, analyze, test, web build`, `Sync — two devices against a real backend`, `Android debug APK — fresh-clone build proof` | `image` and `sync` were made required on 2026-09-14: a merge is followed by a deploy of that very image, and `sync` is the only end-to-end proof of group sharing. No job may get a path filter — a filtered required check leaves a doc-only pull request waiting forever |
| `required_linear_history` | `true` | Merge commits are refused on `main`: **squash** (or rebase) only. The project uses squash |
| `enforce_admins` | `false` | The owner's token can merge red pull requests (`--admin`) and push to `main`; `guard-bash.sh` refuses both instead |
| `allow_force_pushes` | `false` | On `main` only; feature branches are protected from force-pushes by the hook |
| `deleteBranchOnMerge` (repository) | `true` | A merged branch disappears from the remote; its local copy then reads `[gone]` and the hook refuses commits on it |

### Worktrees

- The **main checkout stays on `main`**. Hooks are loaded from
  `${CLAUDE_PROJECT_DIR}/.claude/hooks` — that checkout's files, whatever branch the work is
  on — so the version of the rules in force is the main checkout's.
- Work happens in worktrees: `git worktree add ../countscore-<topic> -b <type>/<topic>
  origin/main` by hand, or `.claude/worktrees/<name>` (branch `worktree-<name>`, gitignored)
  for an agent launched with `isolation: "worktree"`. The Agent tool removes its worktree on
  its own only when the agent changed nothing.
- `scripts/worktree_setup.sh` makes a worktree usable: `flutter pub get`, `build_runner`,
  `gen-l10n`, `uv sync --locked --extra dev`, and symlinks to the untracked
  `backend/scripts/deploy.env` and `android/key.properties` of the main checkout.
- Every hook resolves the repository from the payload `cwd` (followed through `cd` and
  `git -C`): commits are judged and gated in the worktree, and `SubagentStop` asks for the
  pull request of the agent's own branch. See [[Hooks]].
- `gh` on the development machine is 2.45, which has no `gh pr update-branch`; the REST
  call `gh api -X PUT repos/{owner}/{repo}/pulls/<n>/update-branch` does the same.

### Cleaning up — `scripts/cleanup_local.sh`

Dry run by default, `--apply` to act. A local branch goes when it has no commit ahead of
`origin/main`, or when `gh pr list --head <branch> --state merged` finds a pull request and
GitHub's compare of its head against the local tip says `identical` or `behind`. A worktree
(never the main checkout) goes when `git status --porcelain` is empty and its branch goes, or
when it is detached on a commit in `origin/main`. Everything else is printed as `keep` with
the reason. `session-start.sh` points at it whenever a worktree or a `[gone]` branch exists.
Exercised offline by `scripts/hooks_selftest.sh` through a stubbed `gh`.

### Work tracking — `wip/`

`wip/todo/` (release in progress), `wip/todo_nr/` (next release), `wip/done/` (closed), one
file per entry, format in `wip/README.md`, index built by `scripts/wip.sh`. The pre-2026-09-14
`DONE.md` is `wip/done/ARCHIVE-2026-09.md`, frozen.

### What is deployed after a merge

`backend/` → `backend-deploy`; `lib/`, `web/`, `pubspec.*`, `assets/` → `web-deploy`; both →
backend first. `android/`, `store_listing/` and documentation deploy nothing. The Play Store
is never part of the loop: `release-android`, on request.

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
- **`--admin` and pushes to `main` are refused by hook, not by protection.** `enforce_admins`
  is off, so the owner's own token — the one the agents use — could skip every check. The hook
  closes that for Claude without changing what the user can do by hand.
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
