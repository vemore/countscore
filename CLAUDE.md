# CountScore — Instructions for Claude Code

> Budget: ≤ 120 lines; anything past it moves to the wiki page that owns it.

CountScore is a score-tracking app: a Flutter client (Android + web PWA) on Drift/SQLite,
plus a FastAPI backend in `backend/` for group sharing and LLM-generated game commentary.

The backend is **self-hosted by whoever uses it**, and the app ships with no URL for it: the
connected features stay off until a user enters one in Settings → Server. Never reintroduce a
default, and never commit a real deployment host — `--dart-define=BACKEND_URL` is a dev seed
only, and the author's own target lives in the untracked `backend/scripts/deploy.env`.

## Read the wiki first

Durable project knowledge lives in **`.llmwiki/`**, not in this file. **Before any
non-trivial task, read `.llmwiki/INDEX.md` and load the pages your task touches.** Do not
guess at architecture, schema, or deployment — a page already has it. `[[Name]]` in a wiki
page resolves to `.llmwiki/Name.md`.

Repeatable procedures are **skills** in `.claude/skills/` — check them before writing steps
out by hand: `i18n-add-string`, `db-migration`, `release-android`, `backend-deploy`,
`web-deploy`, `flutter-device-test`, `ship-parallel`, `wip-refine`.

Scoped instructions: `backend/CLAUDE.md` (Python/FastAPI) and `.claude/rules/web.md` (PWA —
not in `web/`, because everything under `web/` is published with the build).

## Non-negotiables

1. **Never hardcode a user-facing string.** Always `AppLocalizations` — 10 languages are
   kept in sync. Never hand-roll a plural; use ICU forms. Use the `i18n-add-string` skill.
2. **A fresh clone does not compile until code is generated.** `*.g.dart` is gitignored:
   run `dart run build_runner build` first. No hook checks this one — a generated file that
   exists but is stale looks exactly like a healthy clone.

What a hook refuses outright — build flags, secrets, the web binaries, red gates, the branch,
push and merge shapes — and what the hooks do *not* cover: `.llmwiki/Hooks.md`.

## Workflow

- **Work is tracked one file per entry under `wip/`**, never in a shared list: `todo/` for
  the release in progress, `todo_nr/` for the next, `done/` closed. `wip/README.md`.
- **A problem you find but were not asked to fix becomes a `wip/` entry** — not an inline
  fix, not dropped: `wip/todo_nr/`, or `wip/todo/` when it blocks the release (store policy,
  security, crash, data loss). Then carry on with the task.
- **Tooling that fights you is a `wip/` entry too** — a skill, hook, wiki procedure or this
  file that forced a detour. The entry may propose removing a rule, a hook or a page, not
  only adding one; prefer replacing to adding. `wip/README.md`.
- **An entry you fix moves to `wip/done/` in the same change**, by `git mv`, with a
  `**Status:** done` line. `wip/README.md`.
- **Keep every document a change falsifies true, in the same commit**: its wiki page and
  `Updated:` date, `README.md`, and — for any new outbound data flow — `README.md` Privacy,
  `privacy_policy.md`, `PLAY_STORE_DATA_SAFETY.md` and the manifest permission.
  `.llmwiki/Documentation.md`.
- **Nothing is finished until it is tested and committed.** The commit hook runs the fast
  gates, CI runs the tests; green gates with no commit, or a commit with red gates, are both
  incomplete. `.llmwiki/Hooks.md`.
- **A finished change is a green pull request against `main`.** Push, `gh pr create --base
  main` with a body saying what changed and why, `gh pr checks`, fix what fails, report the
  URL and the check state. Never stack on another branch: wait for it to merge, or put both
  changes in one pull request. A branch held back sets
  `git config branch.<name>.noPullRequest true`, and you say so. `.llmwiki/Hooks.md`.
- **You merge and deploy your own green pull requests, through `ship-parallel`** (decided
  2026-09-14): squash-merge, deploy what the merge changed, smoke-test production; a problem
  found after the deploy is a new pull request. A Play Store release only when the user asks,
  through `release-android`. `.llmwiki/ParallelDelivery.md`.
- **Several tasks at once are several pull requests, in parallel** — one per theme, one
  agent and worktree each: the `ship-parallel` skill.
- **Leave the local environment clean**: the main checkout back on a fast-forwarded `main`,
  then `scripts/cleanup_local.sh` and `--apply` once no agent is working; report what it
  keeps. `.llmwiki/ParallelDelivery.md`.
- **The process gets pruned, not only grown**: this file's budget above, and a pruning pass
  before each release (`release-android` §3b). `.llmwiki/Documentation.md`.

## Commands

```bash
flutter pub get
dart run build_runner build      # required, *.g.dart is gitignored
flutter gen-l10n                 # after touching any .arb
flutter run                      # connected device; -d chrome for web
flutter analyze
flutter test
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

**Start every piece of work on a fresh branch off the current `main`, in its own worktree**,
before the first commit — not after it. The main checkout stays on `main`
(`.llmwiki/ParallelDelivery.md`); the hooks never fetch, so the fetch is on you
(`.llmwiki/Hooks.md`, which also has the recovery from a stale branch).

```bash
git fetch --prune origin
git worktree add ../countscore-<short-topic> -b <type>/<short-topic> origin/main
scripts/worktree_setup.sh ../countscore-<short-topic>    # pub get, codegen, local-only links
```

An agent launched with `isolation: "worktree"` has its worktree already, and switches to
`<type>/<short-topic>` off `origin/main` as its first step.

- Branch names: `<type>/<short-topic>`; commit messages: `feat:`, `fix:`, `refactor:`,
  `docs:`, `chore:`.
- Do not commit build artifacts or generated files.
- Never force-push, and never rewrite a commit already on `origin/main`. Bring a branch up to
  date by merging `main` into it — `gh api -X PUT repos/{owner}/{repo}/pulls/<n>/update-branch`
  — never by rebasing.
