# CountScore — Instructions for Claude Code

CountScore is a score-tracking app: a Flutter client (Android + web PWA) on Drift/SQLite,
plus a FastAPI backend in `backend/` for group sharing and LLM-generated game commentary.

The backend is **self-hosted by whoever uses it**, and the app ships with no URL for it: the
connected features stay off until a user enters one in Settings → Server. Never reintroduce a
default, and never commit a real deployment host — `--dart-define=BACKEND_URL` is a dev seed
only, and the author's own target lives in the untracked `backend/scripts/deploy.env`.

## Read the wiki first

Durable project knowledge lives in **`.llmwiki/`**, not in this file.

**Before any non-trivial task, read `.llmwiki/INDEX.md` and load the pages your task
touches.** Do not guess at architecture, schema, or deployment — a page already has it.

`[[Name]]` in any wiki page resolves to `.llmwiki/Name.md`.

**When you change a durable fact, update its wiki page and its `Updated:` date** in the same
change as the code. A fact that turns out to be wrong gets a `> **Status: Outdated**` block
rather than a silent rewrite.

Repeatable procedures are **skills**, not wiki pages — check `.claude/skills/` before
writing steps out by hand: `i18n-add-string`, `db-migration`, `release-android`,
`backend-deploy`, `web-deploy`, `flutter-device-test`, `ship-parallel`.

Scoped instructions: `backend/CLAUDE.md` (Python/FastAPI) and `.claude/rules/web.md` (PWA —
not in `web/`, because everything under `web/` is published with the build).

## Non-negotiables

1. **Never hardcode a user-facing string.** Always `AppLocalizations` — 10 languages are
   kept in sync. Never hand-roll a plural; use ICU forms. Use the `i18n-add-string` skill.
2. **A fresh clone does not compile until code is generated.** `*.g.dart` is gitignored:
   run `dart run build_runner build` first. No hook checks this one — a generated file that
   exists but is stale looks exactly like a healthy clone.

The rules a hook now refuses outright — build flags, secrets, the two tracked web binaries,
the gates, the branch — are in `.llmwiki/Hooks.md`, with the reasoning that used to sit
here and, more usefully, with what those hooks do *not* cover.

## Workflow

- **Work is tracked one file per entry under `wip/`, never in a shared list.** `wip/todo/`
  is open work for the release in progress, `wip/todo_nr/` for the next one, `wip/done/` is
  closed work. The format, and the frozen archive of the old `DONE.md`, are in
  `wip/README.md`; `scripts/wip.sh list` is the index. A single `TODO.md` conflicted on every
  parallel pull request, and a hook now refuses one.
- **A problem you find but were not asked to fix becomes a `wip/` entry.** When a task
  surfaces something unrelated to it, do not fix it inline and do not drop it: write
  `wip/todo_nr/<date>-<slug>.md` — or `wip/todo/` when it blocks the release in progress (a
  store policy violation, a security flaw, a crash, data loss) — with enough context to act
  on it later, then carry on with the task at hand.
- **Tooling that fights you is a `wip/` entry too.** A skill, a hook, a slash command, a
  wiki procedure or any part of this file that you had to work around — steps that no
  longer match the code, a gate that fires on the wrong thing, a rule that forced a detour,
  something done by hand twice that no skill covers — is the same class of finding as a bug
  in `lib/`. Do not silently absorb the detour and do not leave the next session to
  rediscover it: add a dated `wip/` entry naming the tool, what it actually made you do,
  and the improvement you propose, then carry on with the task at hand. A one-line
  correction that the current task already proves wrong — a renamed file in a skill, a dead
  command — gets fixed inline and mentioned; anything that changes what a tool *does* is a
  proposal, not a detour of its own.
- **An entry you fix moves to `wip/done/` in the same change.** `git mv` it — the file name
  never changes — and add `**Status:** done (YYYY-MM-DD) — closed by <branch>` under its
  title, with what closed it. Never delete an entry, and never edit one another pull request
  owns.
- **`README.md` makes claims about the code — keep them true in the same change.** It is the
  only document a newcomer reads *before* running anything, and it drifted for ten months
  because no rule said when it was implicated. It is implicated whenever a change touches
  one of these:

  | What you changed | What to check in `README.md` |
  |---|---|
  | Flutter/Dart version, or `environment:` in `pubspec.yaml` | Version badge · Prerequisites · Tech stack |
  | A dependency added, removed, or bumped a major | Tech stack |
  | **A step needed to build a fresh clone** | Getting started — a missing step here means a clone does not compile; treat it as a defect, not a doc nit |
  | A build flag, or a new build target | Building for production |
  | A new top-level directory, or a new `lib/` subdirectory | Project structure |
  | A CI job | Continuous integration |
  | Platform support gained or dropped | Platform badge · Getting started · Building |
  | Anything that sends data off the device | Privacy — and the rule below |
  | A feature a user would notice | Features |

  Verify against the source, never against the old README: versions come from
  `pubspec.yaml` and the toolchain table in `.llmwiki/MobileApp.md`, not from the line
  already written. If the change falsifies nothing in that list, the README needs no edit —
  say so and move on rather than touching it for its own sake.

- **A new outbound data flow is a change to three documents, or it is not finished.**
  `README.md` (Privacy), `privacy_policy.md` and `PLAY_STORE_DATA_SAFETY.md` each describe
  what leaves the device. Adding a network call, a new recipient, or a new field to an
  existing payload means updating all three in the same change — and checking that
  `android/app/src/main/AndroidManifest.xml` grants the permission the flow needs, since
  `INTERNET` lives only in the debug and profile manifests by default. A Play Store data
  safety declaration that does not match the binary is a policy violation, not a stale
  line. The audit behind this rule is in `wip/done/ARCHIVE-2026-09.md` (2026-09-09).

- **Nothing is finished until it is tested and committed.** A feature or a bugfix is done
  only once the automated gates covering the code it touches are green *and* the change is
  committed; a hook runs those gates at commit time and refuses the commit while they are
  red (`.llmwiki/Hooks.md`). Green gates with no commit, or a commit with no green gates,
  are both incomplete. Documentation the change falsifies — a wiki page, `README.md`, or
  the privacy documents — belongs in that same commit, not in a follow-up.

- **A finished feature or fix is a pull request, and a green one.** A commit sitting on a
  local branch is not delivered: nothing reviewed it and CI never saw it. When the work is
  done, push the branch, open the pull request with a body saying what changed and why,
  then watch its checks and fix what they find — `gh pr create`, then `gh pr checks`.
  Report the URL and the state of the checks. A hook refuses to end the turn — or a subagent
  to finish — while the commits have no pull request or while its checks are red
  (`.llmwiki/Hooks.md`). A branch deliberately held back sets
  `git config branch.<name>.noPullRequest true`, and you say so rather than doing it
  silently.

- **A pull request targets `main`.** Never stack one on another branch: it merges into that
  base, and if the base is merged first — it usually is — the child's work reaches nowhere,
  while both pull requests read as merged and green. When the work depends on something not
  yet merged, wait for it and merge `main` into your branch, or put both changes in one pull
  request. A hook refuses `gh pr create --base <anything but main>`; stacking anyway is the
  user's decision to take, not yours.

- **You merge and deploy your own green pull requests — through `ship-parallel`.** Decided by
  the user on 2026-09-14: once every required check is green on an up-to-date branch, merge
  with `gh pr merge <n> --squash --delete-branch`, then deploy what the merge changed —
  `backend-deploy` for `backend/`, `web-deploy` for the app — and smoke-test production. A
  problem found after the deploy is a new pull request. Never `--admin`, never a merge commit
  or a rebase merge, never a push to `main` (a hook refuses all three). A Play Store release
  is **not** part of this: only when the user asks, through `release-android`.

- **Leave the local environment clean.** Work is over when the main checkout is back on a
  fast-forwarded `main` and no worktree or local branch is left that no longer serves:
  `scripts/cleanup_local.sh` (dry run), then `--apply`, once no agent is still working. It only
  deletes what has no commit of its own or whose pull request GitHub reports merged; what it
  keeps, you report.

- **Several tasks at once are several pull requests, in parallel.** When the user hands you a
  set of tasks, follow the `ship-parallel` skill: group the entries by theme, one pull request
  per theme, each implemented by its own agent in its own git worktree, then merged one at a
  time and deployed. `.llmwiki/ParallelDelivery.md` has the why.

## Commands

```bash
# Setup
flutter pub get
dart run build_runner build   # required, *.g.dart is gitignored
flutter gen-l10n                                           # after touching any .arb

# Run
flutter run                                                 # connected device
flutter run -d chrome                                       # web

# Quality
flutter analyze
flutter test

# Build
flutter build apk        --release --no-tree-shake-icons
flutter build appbundle  --release --no-tree-shake-icons    # Play Store
flutter build web        --release --no-tree-shake-icons
```

Backend commands are in `backend/CLAUDE.md`.

## Code style

- Follow the Dart style guide and `analysis_options.yaml`.
- `lib/` layout: `screens/` · `widgets/` · `models/` · `services/` · `repositories/` ·
  `providers/` · `utils/` · `l10n/`.
- State goes through Provider; data access goes through a repository interface, never a
  raw database call from a screen.
- Prefer `const` constructors; dispose controllers and listeners.

## Git

**Start every piece of work on a fresh branch off the current `main`, in its own worktree.**
Before the first commit — not after it — run:

```bash
git fetch --prune origin
git worktree add ../countscore-<short-topic> -b <type>/<short-topic> origin/main
scripts/worktree_setup.sh ../countscore-<short-topic>    # pub get, codegen, local-only links
```

An agent launched with `isolation: "worktree"` gets its worktree already made, and switches
to `<type>/<short-topic>` off `origin/main` as its first step. The main checkout stays on
`main`, fast-forwarded: the hooks are read from it, and another session may be working next
to you. The hooks judge the worktree a command runs in, not the main checkout.

Do not carry on committing to whatever branch the working tree happened to be left on: it is
usually the *previous* session's, and once its pull request is merged the remote deletes it.
A hook refuses a commit on `main`, on a detached HEAD, and on a branch it can tell is stale —
but it never fetches, so it only knows what your last `git fetch --prune` left behind. That
is why the fetch above is on you, and why a silent pass is not evidence the branch is live.
The recovery recipe, if you are already on a stale branch, is in `.llmwiki/Hooks.md`.

- Branch names: `<type>/<short-topic>`, using the commit-message types below.
- Commit messages: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`.
- Do not commit build artifacts or generated files.
- Never force-push, and never rewrite a commit that is already on `origin/main` (a hook
  refuses `--force`, `--force-with-lease` and `+refspec`). Bring a branch up to date by
  merging `main` into it — `gh api -X PUT repos/{owner}/{repo}/pulls/<n>/update-branch` — never by rebasing.
