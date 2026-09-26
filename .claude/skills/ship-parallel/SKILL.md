---
name: ship-parallel
description: Implement a set of CountScore wip/ entries in parallel — group them by theme, one pull request per theme, each built by a dedicated agent in its own git worktree; then bring each green pull request up to date, resolve conflicts, squash-merge it into main, deploy the backend and the PWA, smoke-test production, and open follow-up fix pull requests. Use when the user lists several tasks to implement, asks to work in parallel, or asks to merge and deploy finished pull requests. Triggers: "implémente ces tâches", "attaque en parallèle", "lance les PR", "implement these", "work on these in parallel", "merge and deploy", "fusionne et déploie", "ship the todo".
---

# Shipping in parallel

One theme → one worktree → one agent → one pull request → squash-merged into `main` →
deployed. You are the **orchestrator**: you plan, launch, merge, deploy and verify. The agents
implement. The authorisation to merge and deploy is in `CLAUDE.md`; facts and the reasoning
behind each choice: `.llmwiki/ParallelDelivery.md`.

## 0. Where the orchestrator stands

- Work from the **main checkout, on `main`**, kept current: `git fetch --prune origin && git
  merge --ff-only origin/main` (why: `ParallelDelivery.md` § Worktrees).
- If the main checkout is on some other branch with work in it, it belongs to another
  session: do not switch it, ask the user.
- `session-start.sh` lists the existing worktrees and the local branches whose remote is gone.
  A worktree whose pull request is still open is work in flight — resume it rather than
  starting the same theme twice. Debris from a finished loop: `scripts/cleanup_local.sh`
  (§6) before planning anything new, so the next listing shows only live work.
- An open `wip/todo/*-merged-not-deployed.md` entry holds merges an earlier session could not
  deploy (§4): when §1.5 finds the deploy host reachable, deploy `main` and close it first.

## 1. Plan the pull requests

1. `git fetch --prune origin`, then `scripts/wip.sh list all` and read every entry the user
   named (`wip/todo*/`). An entry that is not in `wip/` yet gets written first (`wip/README.md`).
   A `todo_nr/` entry that is not *ready* (`wip-refine` §4) goes through `wip-refine` first.
2. Group by `Theme`, then **split or merge on the files each group will touch**, not on the
   tag alone:
   - two groups editing the same screen, the same Alembic head, or adding strings to the ARB
     files → merge them into one pull request, or run them in two waves;
   - a group that needs another's result (a schema, an endpoint) → a later wave, started
     after the first merges. Never a stacked pull request (the hook refuses `--base`).
   - one pull request stays reviewable: roughly a day of work, one reason to revert, and
     under the 1 500 added-or-modified lines of code §3.1 counts before merging.
3. Order the merges: schema and backend first, then app, then docs and listing. A pull request
   touching `.claude/` (hooks, settings, skills the hooks rely on) merges **last in its wave**,
   once every agent of that wave has reported (why: `ParallelDelivery.md`).
4. **Put each pull request in a lane — A, B, C or D** — from what it is about to touch, now,
   before anything is written (the table, with the full path list:
   `ParallelDelivery.md` § Execution lanes):
   - **A** standard. **B** over 1 500 added-or-modified lines of code (§3.1's count: pure
     deletions, documentation and translations do not count), or a failure that would be
     silent (a migration, the sync contract, an Alembic revision, anything persisted or
     sent to another device), or a call site several features depend on. **C** a diff touching
     the sensitive paths — `backend/app/routes/`, `backend/app/services/{ws_ticket,trusted_proxy,notify}.py`,
     `lib/services/sync/`, `lib/services/backend_client.dart`, `privacy_policy.md`,
     `PLAY_STORE_DATA_SAFETY.md`, `AndroidManifest.xml`. **D** an experiment, on a
     `noPullRequest` branch, never merged as is.
   - Lanes **B and C** need **acceptance criteria in the entry**: if the entry carries none,
     write them with the user now (`wip-refine` §4). §3 refuses the merge without them —
     they are what the independent reviewer judges the tests against.
   - In doubt, take the stricter lane: raising a lane costs one review, missing one costs a
     production fix.
5. **Check that this session can deploy.** A cloud session has no route to the NAS and no
   `deploy.env` (untracked, in the main checkout only), so §4 cannot run there. Read-only,
   over the two routes `deploy_nas.sh` and `deploy_web.sh` take — ssh to the NAS, plain
   HTTP to the registry — and printing no host:
   ```bash
   ( f=backend/scripts/deploy.env
     [ -r "$f" ] || { echo "deploy: no $f in this checkout"; exit 1; }
     set -a; . "$f"; set +a
     ssh -o BatchMode=yes -o ConnectTimeout=5 "$NAS_SSH" true >/dev/null 2>&1 \
       || { echo "deploy: NAS unreachable over ssh"; exit 1; }
     curl -s -o /dev/null -m 5 "http://$REGISTRY/v2/" \
       || { echo "deploy: registry unreachable"; exit 1; }
     echo "deploy: reachable" )
   ```
   Anything but `deploy: reachable` goes **into the plan, as its first line**: "this session
   cannot deploy — merges will land *merged, not deployed* (§4)". The user then chooses
   between merging anyway and leaving the green pull requests for a local session.
6. Present the plan in **one** `AskUserQuestion` — for each pull request: branch name, entries,
   **its lane and, for B and C, the acceptance criteria**, likely files, wave, merge order —
   and, from step 5, whether this session can deploy; then wait for the answer. The user's go-ahead covers the whole loop below, merges and deploys
   included; it does **not** stand in for lane C's go-ahead in §3, which is asked again once
   the diff and the review findings exist.

Five agents at a time at most. Parallel `flutter test` runs queue on the SDK lock anyway, and
each worktree costs a `pub get` and a `build_runner`.

## 2. Launch one agent per pull request

All agents of a wave in **one message**, each with `isolation: "worktree"` and
`run_in_background` left to the default. The tool creates the worktree under
`.claude/worktrees/<name>` on a branch `worktree-<name>`; the agent moves to a proper branch
first. Fill in this prompt — do not shorten the rules part:

```text
You implement one pull request of CountScore, in the git worktree you start in.

Pull request: <type>/<topic> — <one-line goal>
Entries to close: <wip/todo/....md paths>
Lane: <A | B | C>. <For B and C: this change is reviewed by another agent before it merges;
the acceptance criteria below are what that review judges your tests against.>
Acceptance criteria (B and C): <the entries' criteria, one per line>
Files you will likely touch: <list>. Other agents are working in parallel on: <other PRs and
their files> — stay out of those files; if you cannot, say so in your report.

Rules:
1. First: `git fetch --prune origin && git switch -c <type>/<topic> origin/main`, then
   `scripts/worktree_setup.sh` (add --no-app or --no-backend when one side is untouched).
2. Read CLAUDE.md, .llmwiki/INDEX.md and the pages the change touches. Use the project skills
   that cover the work (i18n-add-string, db-migration, ...).
3. Implement, with tests. Update the wiki pages, README.md and privacy documents the change
   falsifies, in the same pull request.
4. Close each entry in the same pull request: `git mv wip/todo/X.md wip/done/X.md` and add the
   `**Status:** done (YYYY-MM-DD) — closed by <type>/<topic>. ...` line (wip/README.md). A
   problem you find but were not asked to fix becomes a new entry in wip/todo_nr/ (or
   wip/todo/ if it blocks the release) — never fix it inline, never edit another entry.
5. Commit (the hook runs the gates in this worktree), `git push -u origin <type>/<topic>`,
   `gh pr create --base main` with a body saying what changed and why.
6. Watch `gh pr checks <n> --watch` and fix what fails until every check is green **or
   skipped** — the `scope` job rules out the jobs the change does not need, and a job it
   skipped reports `skipping`, which counts as passing.
   Circuit breaker: after three fix attempts on the same failing check (or the same failing
   test locally), stop — no fourth attempt, no loosened assertion, no skipped test. Report
   the failure as one of TEST_ISSUE (the test is wrong or asks for something the entry does
   not), IMPL_ISSUE (the code cannot meet the test as far as you can tell), DOC_ISSUE (a doc,
   wiki or entry is contradictory or wrong, and you cannot tell which side to trust) or
   UNCLEAR, with the check name, the last error and what the three attempts tried.
7. Never merge, never deploy, never force-push, never push to main.
8. Report, briefly: PR URL and number, check state, files touched, Alembic revisions, ARB keys
   added, anything the orchestrator must know to merge or deploy (env vars, migrations,
   manual steps), entries you created, and — if the circuit breaker tripped — its class. On
   lanes B and C, map **each acceptance criterion to the test that covers it**, by name.
```

A `SubagentStop` hook refuses to let an agent finish while its commits have no pull request
or while its checks are red, so a report without a green pull request means the agent was
blocked twice — read why before relaunching. When the report carries a circuit-breaker
class, act on the class, and never relaunch the same prompt unchanged:

| Class | What the orchestrator does |
|---|---|
| `TEST_ISSUE` | Read the test against the entry's Acceptance. If the test is wrong, `SendMessage` the agent (or a fresh one on the same branch) the correction; if it is right, treat it as `IMPL_ISSUE`. |
| `IMPL_ISSUE` | Read the last error and the three attempts yourself; relaunch with the diagnosis in the prompt, or narrow the pull request and move the rest to a new `wip/` entry. |
| `DOC_ISSUE` | Decide which side is true — ask the user if it changes what the entry asks for — and relaunch with that answer. |
| `UNCLEAR` | Ask the user, with the agent's evidence; the pull request waits and merges after its wave. |

## 3. Merge, one pull request at a time

`main` requires an up-to-date branch, the five CI checks green or skipped, and a linear history
(`.llmwiki/ParallelDelivery.md`). So merges are serial. For each pull request, in the planned
order:

1. `gh pr view <n> --json state,mergeable,mergeStateStatus,headRefName` and read the diff
   (`gh pr diff <n>`) — you are the only reviewer. Check it closes its entries and touches
   what its report says. Then its size: the **added or modified lines of code**, which is what
   one review has to hold in its head. A pure deletion costs nothing, and documentation,
   translations, generated, lock, binary and test files are not counted at all — removing dead
   code and translating into ten languages are two of the things this project most wants cheap:
   ```bash
   gh pr diff <n> | awk '
     /^diff --git / { p = $4; sub(/^b\//, "", p)
                      keep = (p !~ /\.md$|^wip\/|\.arb$|app_localizations.*\.dart$|\.g\.dart$|\.lock$|^web\/sqlite3\.wasm$|^web\/drift_worker\.js$|^test\/|^integration_test\/|^backend\/tests\//) }
     keep && /^\+/ && !/^\+\+\+/ { n++ }
     END { print n + 0 }'
   ```
   It counts the `+` lines of the kept files, the `+++` headers aside. A modified line appears
   in a diff as one `-` and one `+`, so that is exactly *added or modified*, and a removed line
   adds nothing. It has to be measured on the **diff**: `gh pr view --json files` knows only
   `additions` and `deletions` per path, cannot tell a modified line from an added one, and
   would charge the deletions on top — the formula that made a pull request deleting two dead
   guides measure 1 590 (`ParallelDelivery.md` § Decisions).
   Above **1 500** counted lines the pull request is lane B whatever the plan said: this count
   is the **backstop** for a lane misjudged at planning time, not the gate itself. Run step 2
   for it, and do not merge without the user's go-ahead — #21 (+6.9 k) was merged on its size
   alone and needed six fix pull requests the same day.
2. **Apply the lane** chosen in §1 (`ParallelDelivery.md` § Execution lanes). Lane **A**:
   nothing more, go to step 3. Lanes **B and C**, before the merge:
   - Check the entry's acceptance criteria against the agent's report — each one mapped to a
     test. Criteria missing: write them from the entry and check the diff against them first.
   - Launch a **fresh agent that did not write the change** (never the implementing one) on
     the pull request: `/code-review high <n>`, and give it the entries, their acceptance
     criteria and the four calibration rules of `ParallelDelivery.md` § The independent
     reviewer's calibration.
   - Report **every** finding to the user, with what you intend to do about each: fixed in
     this pull request, a new `wip/` entry, or dismissed and why. A finding showing the change
     does not do what its entry promised goes back to the implementing agent before the merge;
     a durable problem beyond this pull request's scope becomes a `wip/` entry and, if it
     belongs in this release, its own pull request.
   - Lane **C** only: ask an explicit `AskUserQuestion` go-ahead **for this merge**, after the
     findings. The §1 plan approval does not cover it, and no CODEOWNERS gate exists.
   Lane **D** never reaches this section: its branch carries `noPullRequest` and is not merged.
3. Bring it up to date: `gh api -X PUT repos/{owner}/{repo}/pulls/<n>/update-branch`. (`gh pr update-branch`
   needs gh ≥ 2.49; this machine has 2.45). It merges `main` into the branch on GitHub — no rebase, no force-push, and the agent's worktree stays valid.
4. If GitHub reports a conflict, resolve it in that pull request's worktree:
   `git -C <worktree> fetch origin && git -C <worktree> merge origin/main`, fix, commit (the
   hook runs the gates on what differs from `main` — `.llmwiki/Hooks.md`), `git push`. Recipes:
   - **`lib/l10n/*.arb`** — keep the union of the keys, valid JSON, same order as the
     template; then `flutter gen-l10n`. Never hand-merge `app_localizations*.dart`: take either
     side and regenerate.
   - **Alembic** — two revisions with the same `down_revision`: point the later one at the
     other (`alembic heads` must print one head), then re-run the backend tests.
   - **`.llmwiki/*.md`** — keep both facts, and the later `Updated:` date; `INDEX.md` too.
   - **`pubspec.lock` / `uv.lock`** — take `main`'s, then `flutter pub get` / `uv lock`.
   - **`wip/`** — two branches never touch the same entry; a conflict there means one of them
     edited an entry it did not own: keep the owner's version.
   - Anything that is a real semantic clash between two themes: stop and tell the user.
5. `gh pr checks <n> --watch` — all green or `skipping`, on the updated head.
6. `gh pr merge <n> --squash --delete-branch` (the hook refuses `--admin`, `--merge`,
   `--rebase`). Then `git fetch --prune origin && git merge --ff-only origin/main` in the main
   checkout.
7. The next pull request is now behind `main`: back to step 3 for it.

## 4. Deploy what the merge changed

After **each** merge, so a regression points at one pull request. List what changed:
`git diff --name-only <sha>^ <sha>` on the squash commit.

| Paths changed | Do |
|---|---|
| `backend/` (code, `Dockerfile`, `alembic/`, compose) | `backend-deploy` skill — migrations included, then `/health` |
| `lib/`, `web/`, `pubspec.*`, `assets/` | `web-deploy` skill |
| both | backend first, then web |
| only `android/`, `store_listing/`, docs, `wip/`, `.claude/`, CI | nothing to deploy |

Deploy from a clean tree at the merged commit, never from an agent's worktree (it is detached
on `main`, so §6 removes it once the loop is over):
`git worktree add ../countscore-deploy origin/main` (or `git -C ../countscore-deploy switch
--detach origin/main` when it exists), then `scripts/worktree_setup.sh --deploy ../countscore-deploy`:
`--deploy` links the untracked
`backend/scripts/deploy.env`, which no other worktree gets. Run the deploy skill there.

Then smoke-test production: `/health`, the PWA loads, and the path the pull request changed,
driven for real (Playwright on the PWA, `flutter-device-test` for the Android app when only
a device shows it). Record what you checked.

**When the deploy cannot run** — §1.5 said so, or the deploy skill cannot reach the NAS or the
registry — the merge is **merged, not deployed**, never a silent success (#212–#216 sat
undeployed for days that way: `ParallelDelivery.md` § Decisions). A deploy that ran and broke
production is not this case: that is §5's rollback.
- Say "merged, not deployed" for that pull request, then and in §6.
- File **one** entry for the loop, `wip/todo/<date>-merged-not-deployed.md` (Theme
  `deploy-safety`, Blocks release: yes), or add to the one already open: one line per squash
  sha, with its pull request and what it needs, from the table above — **backend with
  Alembic** (name the revision: `git diff --name-only <sha>^ <sha> -- backend/alembic/versions`),
  **backend, no Alembic**, **PWA**. Its fix: deploy `origin/main`, backend first, then web —
  one deploy covers every sha listed — smoke-test each listed pull request's path, and close
  the entry naming the deployed sha.
- The entry reaches `main` through its own `docs/` pull request, merged after the last one of
  the loop (it touches only `wip/`: nothing to deploy).

## 5. Follow-up fixes

A problem found after the deploy is a **new** pull request, never a commit on the merged
branch (the hook refuses it once the branch is gone): write the entry in `wip/todo/`, launch
one agent with the same prompt, then merge and deploy it through §3–§4. A deploy that broke
production is rolled back first (`backend-deploy` / `web-deploy` both have a rollback), then
fixed.

## 6. Clean up and report

The loop is not finished while it leaves debris: the local environment ends with the main
checkout on `main`, fast-forwarded, and only the worktrees and branches of work still in
flight. A loop leaves four kinds of leftovers — agent worktrees under `.claude/worktrees/`,
the `worktree-<name>` branch each agent abandoned for its real branch, the deploy worktree,
and one local branch per merged pull request.

- Once **every agent has reported** (a clean worktree on a branch with no commit yet looks
  abandoned): `scripts/cleanup_local.sh` — a dry run listing what goes and why — then
  `scripts/cleanup_local.sh --apply` (what it proves before deleting:
  `ParallelDelivery.md` § Cleaning up).
- Read the `keep` lines. An unmerged pull request, a dirty worktree or local commits beyond a
  merged head are real: say so in the report, never force them away. A pull request closed
  without merging is the user's call.
- `git worktree list` and `git branch -vv` must then show only `main` and work in flight.
- Report to the user: each pull request (URL, merged or not), each deploy and its smoke test
  — or, for each merge §4 could not deploy, **"merged, not deployed"** with its sha and the
  `merged-not-deployed` entry — the entries created on the way, and what is left
  (`scripts/wip.sh list`).
- And the **delivery metrics** since the last release tag: `scripts/delivery_metrics.sh`,
  pasted as printed. Name any figure worse than the baseline in `.llmwiki/ParallelDelivery.md`
  § Measuring delivery (rework rate, change failure rate, first-run-green); do not act on it
  here — the `release-android` §3b pruning pass does.
- And an **Android** line — how far the Play Store lags production: the last release tag
  (`git describe --tags --abbrev=0 origin/main`), the commits since
  (`git rev-list --count <tag>..origin/main`), and the open `wip/todo/` entries
  (`scripts/wip.sh list todo`). Once `wip/todo/` is empty, propose a `release-android` run
  (`.llmwiki/Release.md`); run it only when the user asks.
