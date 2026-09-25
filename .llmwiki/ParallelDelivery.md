# ParallelDelivery

> Scope: how several changes are built at once and reach production — worktrees, one pull
> request per theme, the execution lane a change's risk puts it in, serial squash merges,
> deploy after each merge, and `wip/` work tracking.
> Procedure: the `ship-parallel` skill. Related: [[Hooks]] · [[Deployment]] · [[Release]]
> Updated: 2026-09-25

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
  `gen-l10n` (`--no-app` skips them), `uv sync --locked --extra dev` (`--no-backend`). It
  links **no secret by default**: `--deploy` symlinks the main checkout's untracked
  `backend/scripts/deploy.env` (the orchestrator's deploy worktree, `ship-parallel` §4) and
  `--release` its `android/key.properties` (the release worktree). An implementing agent
  never deploys and never signs, so its worktree reaches neither (`scripts/hooks_selftest.sh`
  checks each flag). While it runs it holds `<worktree>/.countscore-setup-in-progress` (pid, date, branch; gitignored,
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

Three guards run **before** every other rule in the worktree loop, lock first, and each keeps
the worktree's **branch** as well as the worktree — without that the branch loop deletes the
branch out from under a live worktree:

| Guard | Evidence | Printed as |
|---|---|---|
| Locked by a running session | `git worktree list --porcelain` has `locked claude agent <name> (pid N start T)` — Claude Code's lock — and pid N is alive and, where `/proc/N/stat` field 22 is readable, still started at T | `keep … — locked by a running session (pid N)` |
| Locked by hand | a `locked` line naming no pid | `keep … — locked: <reason>` |
| Setup in progress | `<worktree>/.countscore-setup-in-progress` exists | `keep … — setup in progress (.countscore-setup-in-progress)` |
| An agent may be working | `find <worktree> -newermt "-$CLEANUP_IDLE_MINUTES minutes" -print -quit` finds anything | `keep … — modified in the last N minutes (an agent may be working)` |

`CLEANUP_IDLE_MINUTES` defaults to `30`; `0` disables the modification-time guard only — a
live lock and the marker are always honoured. A lock whose pid is gone (or recycled: a
different start time) is **stale**: the worktree then goes through the usual rules, is listed
as `would remove … ; stale lock, pid N is gone`, and `--apply` removes it with
`git worktree remove -f -f`. Whenever a removal fails, `--apply` prints git's error, indented,
under the `FAILED` line. The self-test runs its first `--apply` with `CLEANUP_IDLE_MINUTES=0`,
because its sandbox worktrees are created seconds earlier and would otherwise all be kept.

None of the guards makes `--apply` safe to run while agents work: an unlocked worktree idle
for more than the window, with a branch that carries no commit yet, still looks abandoned.
They cover the windows that cost work in practice — a live agent session, the five-minute
setup, and an agent between commits.

### Execution lanes — the path to production is chosen by the risk

A change is put in a lane when the pull requests are **planned** (`ship-parallel` §1), from
what it is about to touch — not once the diff exists. The lane is named in the plan the user
approves, and `ship-parallel` §3 applies what it requires before the merge.

| Lane | What falls in it | What it requires before merging |
|---|---|---|
| **A — standard** | Everything the other three do not catch | Today's loop: checks green or skipped, the orchestrator reads the diff, squash-merge, deploy |
| **B — planned** | Over **1 500** added or modified lines of **code** — pure deletions, documentation, translations, generated, lock, binary and test files are not counted (`ship-parallel` §3.1); or a failure that would be **silent** — a migration, the sync contract, an Alembic revision, anything persisted or sent to another device; or a call site several features depend on | Lane A, plus **acceptance criteria in the entry** (mandatory here, `wip/README.md`), plus `/code-review high` run by an agent that did **not** write the change, its findings reported to the user before the merge |
| **C — sensitive paths** | A diff touching `backend/app/routes/`, `backend/app/services/{ws_ticket,trusted_proxy,notify}.py`, `lib/services/sync/`, `lib/services/backend_client.dart`, `privacy_policy.md`, `PLAY_STORE_DATA_SAFETY.md`, `AndroidManifest.xml` | Lane B, plus an explicit `AskUserQuestion` go-ahead for that merge, asked after the findings |
| **D — experiment** | A spike written to learn something, not to ship | A branch held back with `git config branch.<name>.noPullRequest true`, never merged as is; what it taught becomes a `wip/` entry |

A change matching several lanes takes the strictest, and the orchestrator may raise a lane at
any moment — raising one costs a review, missing one costs a production fix. The `ship-parallel`
§3.1 size count stays only as the **backstop** for a lane misjudged at planning time: a lane-A
pull request that turns out to be over 1 500 counted lines is lane B after all.

Nothing mechanical enforces the lanes. `SubagentStop` is unchanged and still checks only that
an agent leaves a pull request whose checks are not red ([[Hooks]]); lane C's approval is an
`AskUserQuestion` in the session, not CODEOWNERS, which would block a solo self-merge outright.

### The independent reviewer's calibration (lanes B and C)

The reviewing agent is **fresh** — the agent that writes a change also writes the tests that
judge it. It gets `/code-review high` on the pull request, the entries with their acceptance
criteria, and these four rules, which a generic reviewer does not know:

- **Verify each finding against the pull request head**, not against its description or an
  earlier commit.
- **A wiki page, `README.md` or privacy document the change makes false is at least Medium** —
  documentation is part of the change here ([[Documentation]]).
- **Read a page's `Decisions & History` before calling something redundant**: most of what
  looks duplicated was argued for once and kept on purpose.
- **Judge the tests against the entry's acceptance criteria**, not against coverage: the
  question is whether what the entry promised is proven.

Every finding goes to the user before the merge, whatever its severity, with what the
orchestrator intends to do about it.

### Work tracking, and what a merge deploys

Work tracking: `wip/README.md`. What enters `wip/todo/` is decided by a refinement pass
(`wip-refine`): the move from `todo_nr/` is the commitment point, `todo/` holds at most 12
entries, and an entry needs to be *ready* (still true, one pull request, acceptance criteria,
unblocked, themed) to be promoted. What a merge deploys, and how: `ship-parallel` §4 — the Play
Store is never part of the loop (`release-android`, on request).

### A session that cannot reach the deploy host

Only a session on the author's network can deploy: the deploy goes over ssh to the NAS and
pushes to its plain-HTTP registry ([[Deployment]]), and the target lives in the untracked
`backend/scripts/deploy.env`, present in the main checkout only. A cloud session has neither,
yet can merge on GitHub as well as any. So `ship-parallel` §1.5 probes, at planning time and
read-only, what §4 will need — `deploy.env` readable, `ssh -o BatchMode=yes` to `$NAS_SSH`,
an HTTP answer from `$REGISTRY/v2/` — printing a verdict and never the host, and the plan
opens with "this session cannot deploy" when any of them fails. A merge whose deploy cannot
run is reported **merged, not deployed**, in §4 and in §6's report, and lands in one
`wip/todo/<date>-merged-not-deployed.md` entry listing each squash sha with what it needs
(backend with its Alembic revision, backend without, PWA). The next session that can reach the
NAS sees it at `ship-parallel` §0 and deploys `main`, which covers every sha listed at once.

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
- **A refinement pass decides what enters `wip/todo/` (2026-09-18).** With 43 entries in
  `todo_nr/` and `wip/README.md` saying only "the user decides", nothing sorted the stale from
  the ready, closed the obsolete (entries could not be deleted, and `done/` accepted only
  `Status: done`), or noticed that one entry already replaced two others. Borrowed from
  standard practice: a definition of ready and acceptance criteria (Scrum, INVEST); a backlog
  detailed only near its top (DEEP); the commitment point and a WIP limit (Kanban
  replenishment); dropping freely, because an idea that matters comes back (Shape Up); and
  hygiene before ranking. RICE and WSJF were rejected: for one developer and a few dozen
  entries they cost more than they decide, and reach cannot be measured on 6 monthly devices.
  A cost-of-delay class, then value against cost, ranks instead. The pass proposes, and the
  user decides.
- **Worktrees get secrets only on request (2026-09-18).** `worktree_setup.sh` used to link
  `deploy.env` and `key.properties` into every worktree, the implementing agents' included,
  though those agents never deploy or sign. Following "Your SDLC is your context engineering"
  (LeadDev, 2026-08-10), what an agent can reach is scoped to what its task needs: no link by
  default, `--deploy` for the deploy worktree, `--release` for the release worktree. A worktree
  set up before the change keeps its links until it is removed.
- **The 1 500-line merge check leaves test code out (2026-09-18).** The `ship-parallel` §3.1
  filter already dropped generated, lock and binary files; it now also drops `test/`,
  `integration_test/` and `backend/tests/`. Counting them made a thoroughly tested pull
  request look bigger than an untested one, so the cap pushed against the tests the project
  most wants — the same article excludes test files from its size limits for that reason. The
  cap is about how much production code one review has to hold, not how much is verified.
- **And it counts added or modified code only (2026-09-20).** `docs/brand-guides` (#199)
  measured **1 590** lines by that formula — `additions + deletions` over the kept paths — and
  so needed the user's go-ahead, although it contained no application code beyond a ten-line
  comment: **1 026** of those lines were the *deletion* of two dead purple design guides,
  `ICON_DESIGN_GUIDE.md` (612) and `COLOR_THEME_GUIDE.md` (414), which an entry had explicitly
  asked for, and 269 were a new Pillow script. A cap that counts deletions and documentation
  taxes cleanup and translation, the two things the project most wants cheap. The **1 500
  threshold is unchanged**; what is counted is now the added or modified lines of code — no
  pure deletions, no `*.md` or `wip/`, no `*.arb` or `app_localizations*.dart`, on top of the
  generated, lock, binary and test exclusions. It is measured on the diff rather than through
  `gh pr view --json files`, which knows only `additions` and `deletions` per path and cannot
  tell a modified line from an added one. Re-measured with the new command: #199 counts 279,
  #192 counts 50 — its lane B came from the silent-failure trigger, not from its size — and a
  documentation-only pull request counts 0.
- **An implementing agent stops after three attempts on one failing check (2026-09-18).** The
  agent that writes a change also writes the tests that judge it, and the `SubagentStop` hook
  refuses to let it finish on red checks: together they reward the cheapest way to green — a
  missing case, a loosened assertion, a fixture never written (#75 shipped with no v4
  fixture) — and nothing stopped an agent looping on the same failure. The `ship-parallel` §2
  prompt now carries a circuit breaker: three fix attempts on one check, then a report classed
  `TEST_ISSUE`, `IMPL_ISSUE`, `DOC_ISSUE` or `UNCLEAR`, each with its own orchestrator action.
  A separate **test-designer subagent**, writing the tests before the implementing agent
  starts, was considered and **dropped**: the acceptance criteria an entry must carry to reach
  `wip/todo/`, plus the independent review planned for the riskier lanes
  (the entry `2026-09-18-one-lane-for-every-change`, lanes B and C) were judged enough, at the
  2026-09-18 refinement, to keep an agent from grading its own work.

- **Execution lanes A–D (decided 2026-09-18, first run 2026-09-20).** `ship-parallel` ran a
  one-line wording fix and a sync-contract change through the same loop, and the only brake was
  the 1 500-line count at §3.1 — applied after the code existed. Following "Your SDLC is your
  context engineering" (LeadDev, 2026-08-10), the path to production is now chosen by the risk
  at planning time. The lane table replaced two entries that each held half of it (one keyed on
  sensitive paths, one on the shape of the change), a third that gave the reviewer its four
  calibration rules, and a fourth that made acceptance criteria mandatory for lanes B and C.
  Evidence: **#21** (+6.9 k lines, 64 files) was merged and deployed the day it opened and
  needed six fix pull requests (#22–#27) the same day, a crash and security findings among
  them; and **#75**'s planned review found a v4→v5 migration that left the database
  unopenable — six CI checks were green and there was no v4 fixture. CODEOWNERS was rejected
  for lane C (it blocks a solo self-merge), and `SubagentStop` was deliberately left alone: the
  lane is the orchestrator's step, not the implementing agent's.
- **The first lane-B run paid for itself the same day (2026-09-20).** #192
  (`fix/rules-slug-restore`, a v18 schema step restoring wiped `rules_slug` values) was planned
  as lane B; the independent reviewer confirmed the repair but found that it is **not durable**,
  because a NULL `rules_slug` travels through the sync and writes the damage straight back
  (`sync_store.dart:458`, `:748`, and the backend keeping null-valued known columns). A query
  against the production database confirmed it was real rather than theoretical: the
  four-device group the owner actually uses held a ZapZap row with `builtin_key='zapzap'` and
  `rules_slug` NULL. Six CI checks were green on #192 throughout — which is the concrete answer
  to "why not just trust the checks". The repair became `fix/rules-slug-payload`.
- **A merge that cannot be deployed says so (2026-09-25).** The run that squash-merged
  #212–#216 was a cloud session with no route to the NAS: `backend-deploy` and `web-deploy`
  could not run, the loop ended as if it had succeeded, and production kept a backend from
  2026-09-20 until a device test found `PATCH /groups/devices/me` answering `404`
  (`wip/` entry `2026-09-25-production-backend-lacks-the-device-rename-endpoint`). The user
  asked for the step to be impossible to skip silently rather than for cloud sessions to stop
  merging: a reachability probe at planning time, so the user knows before the go-ahead, and
  "merged, not deployed" plus one `wip/todo/` entry naming the shas, so the next local session
  deploys them. The probe reuses the deploy's own routes (ssh, the registry) rather than
  `PUBLIC_URL`, because the public API answers from anywhere and proves nothing about the NAS.
