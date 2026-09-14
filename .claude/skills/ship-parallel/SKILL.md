---
name: ship-parallel
description: Implement a set of CountScore wip/ entries in parallel — group them by theme, one pull request per theme, each built by a dedicated agent in its own git worktree; then bring each green pull request up to date, resolve conflicts, squash-merge it into main, deploy the backend and the PWA, smoke-test production, and open follow-up fix pull requests. Use when the user lists several tasks to implement, asks to work in parallel, or asks to merge and deploy finished pull requests. Triggers: "implémente ces tâches", "attaque en parallèle", "lance les PR", "implement these", "work on these in parallel", "merge and deploy", "fusionne et déploie", "ship the todo".
---

# Shipping in parallel

One theme → one worktree → one agent → one pull request → squash-merged into `main` →
deployed. You are the **orchestrator**: you plan, launch, merge, deploy and verify. The agents
implement. Facts and the reasoning behind each choice: `.llmwiki/ParallelDelivery.md`.

The user has authorised this loop to **merge its own green pull requests and deploy the
backend and the PWA** (decided 2026-09-14). A Play Store release is not part of it: only on
an explicit request, through `release-android`.

## 0. Where the orchestrator stands

- Work from the **main checkout, on `main`**, kept current: `git fetch --prune origin && git
  merge --ff-only origin/main`. The hooks are read from this checkout
  (`${CLAUDE_PROJECT_DIR}/.claude/hooks`), so it must carry the latest ones. It never commits
  (the hook refuses a commit on `main`) — every change is made in a worktree.
- If the main checkout is on some other branch with work in it, it belongs to another
  session: do not switch it, ask the user.
- `session-start.sh` lists the existing worktrees and the local branches whose remote is gone.
  A worktree whose pull request is still open is work in flight — resume it rather than
  starting the same theme twice. Debris from a finished loop: `scripts/cleanup_local.sh`
  (§6) before planning anything new, so the next listing shows only live work.

## 1. Plan the pull requests

1. `git fetch --prune origin`, then `scripts/wip.sh list all` and read every entry the user
   named (`wip/todo*/`). An entry that is not in `wip/` yet gets written first (`wip/README.md`).
2. Group by `Theme`, then **split or merge on the files each group will touch**, not on the
   tag alone:
   - two groups editing the same screen, the same Alembic head, or adding strings to the ARB
     files → merge them into one pull request, or run them in two waves;
   - a group that needs another's result (a schema, an endpoint) → a later wave, started
     after the first merges. Never a stacked pull request (the hook refuses `--base`).
   - one pull request stays reviewable: roughly a day of work, one reason to revert, and
     under the 1 500-line cap §3 checks before merging.
3. Order the merges: schema and backend first, then app, then docs and listing.
4. Present the plan in **one** `AskUserQuestion` — for each pull request: branch name, entries,
   likely files, wave, merge order — and wait for the answer. The user's go-ahead covers the
   whole loop below, merges and deploys included.

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
6. Watch `gh pr checks <n> --watch` and fix what fails until every check is green.
7. Never merge, never deploy, never force-push, never push to main.
8. Report, briefly: PR URL and number, check state, files touched, Alembic revisions, ARB keys
   added, anything the orchestrator must know to merge or deploy (env vars, migrations,
   manual steps), and entries you created.
```

A `SubagentStop` hook refuses to let an agent finish while its commits have no pull request
or while its checks are red, so a report without a green pull request means the agent was
blocked twice — read why before relaunching.

## 3. Merge, one pull request at a time

`main` requires an up-to-date branch, all five CI checks green and a linear history
(`.llmwiki/ParallelDelivery.md`). So merges are serial. For each pull request, in the planned
order:

1. `gh pr view <n> --json state,mergeable,mergeStateStatus,headRefName` and read the diff
   (`gh pr diff <n>`) — you are the only reviewer. Check it closes its entries and touches
   what its report says. Then its size, generated, lock and binary files left out:
   ```bash
   gh pr view <n> --json files --jq '[.files[] | select(.path | test("\\.g\\.dart$|^lib/l10n/app_localizations.*\\.dart$|^pubspec\\.lock$|^backend/uv\\.lock$|^web/sqlite3\\.wasm$|^web/drift_worker\\.js$") | not) | .additions + .deletions] | add'
   ```
   Above **1 500** lines, do not merge without the user's go-ahead: #21 (+6.9 k) needed six
   fix pull requests the same day. (`files` stops at 100 entries: a pull request that long
   needs the go-ahead anyway.)
2. Bring it up to date: `gh api -X PUT repos/{owner}/{repo}/pulls/<n>/update-branch`. (`gh pr update-branch`
   needs gh ≥ 2.49; this machine has 2.45). It merges `main` into the branch on GitHub — no rebase, no force-push, and the agent's worktree stays valid.
3. If GitHub reports a conflict, resolve it in that pull request's worktree:
   `git -C <worktree> fetch origin && git -C <worktree> merge origin/main`, fix, commit (the
   hook runs the gates), `git push`. Recipes:
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
4. `gh pr checks <n> --watch` — all green, on the updated head.
5. `gh pr merge <n> --squash --delete-branch` (the hook refuses `--admin`, `--merge`,
   `--rebase`). Then `git fetch --prune origin && git merge --ff-only origin/main` in the main
   checkout.
6. The next pull request is now behind `main`: back to step 2 for it.

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
--detach origin/main` when it exists), then `scripts/worktree_setup.sh ../countscore-deploy`,
which links the untracked `backend/scripts/deploy.env`. Run the deploy skill there.

Then smoke-test production: `/health`, the PWA loads, and the path the pull request changed,
driven for real (Playwright on the PWA, `flutter-device-test` for the Android app when only
a device shows it). Record what you checked.

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
  `scripts/cleanup_local.sh --apply`. It removes a clean worktree and deletes a branch only
  when the branch has no commit of its own, or when GitHub reports its pull request merged
  and the local tip inside the merged head. Squash merges make `git branch -d` useless here
  and `-D` unsafe; this is the check in between.
- Read the `keep` lines. An unmerged pull request, a dirty worktree or local commits beyond a
  merged head are real: say so in the report, never force them away. A pull request closed
  without merging is the user's call.
- `git worktree list` and `git branch -vv` must then show only `main` and work in flight.
- Report to the user: each pull request (URL, merged or not), each deploy and its smoke test,
  the entries created on the way, and what is left (`scripts/wip.sh list`).
- And an **Android** line — how far the Play Store lags production: the last release tag
  (`git describe --tags --abbrev=0 origin/main`), the commits since
  (`git rev-list --count <tag>..origin/main`), and the open `wip/todo/` entries
  (`scripts/wip.sh list todo`). Once `wip/todo/` is empty, propose a `release-android` run
  (`.llmwiki/Release.md`); run it only when the user asks.
