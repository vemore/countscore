# CountScore — Instructions for Claude Code

CountScore is a score-tracking app: a Flutter client (Android + web PWA) on Drift/SQLite,
plus a FastAPI backend in `backend/` for group sharing and LLM-generated game commentary.

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
`backend-deploy`, `flutter-device-test`.

Scoped instructions: `backend/CLAUDE.md` (Python/FastAPI) and `web/CLAUDE.md` (PWA).

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

- **A problem you find but were not asked to fix goes in `TODO.md`.** When a task surfaces
  something unrelated to it, do not fix it inline and do not drop it: add an entry to
  `TODO.md`, dated, with enough context to act on it later — then carry on with the task
  at hand.
- **A `TODO.md` item you fix moves to `DONE.md` in the same change.** Do not delete the
  entry and do not leave it in `TODO.md`: cut it whole, write
  `**Status:** done (YYYY-MM-DD)` on it, and paste it at the top of `DONE.md` — newest
  first — with a line saying what closed it. `TODO.md` then holds only open work, and the
  reasoning behind a closed item stays readable in `DONE.md`.
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
  line. The audit behind this rule is in `DONE.md` (2026-09-09).

- **Nothing is finished until it is tested and committed.** A feature or a bugfix is done
  only once the automated gates covering the code it touches are green *and* the change is
  committed; a hook runs those gates at commit time and refuses the commit while they are
  red (`.llmwiki/Hooks.md`). Green gates with no commit, or a commit with no green gates,
  are both incomplete. Documentation the change falsifies — a wiki page, `README.md`, or
  the privacy documents — belongs in that same commit, not in a follow-up.

## Commands

```bash
# Setup
flutter pub get
dart run build_runner build   # required, *.g.dart is gitignored
flutter gen-l10n                                           # after touching any .arb

# Run
flutter run                                                 # connected device
flutter run -d chrome --dart-define=BACKEND_URL=<url>       # web

# Quality
flutter analyze
flutter test

# Build
flutter build apk        --release --no-tree-shake-icons
flutter build appbundle  --release --no-tree-shake-icons    # Play Store
flutter build web        --release --no-tree-shake-icons --dart-define=BACKEND_URL=<url>
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

**Start every session on a fresh branch off the current `main`.** Before the first commit of
a session — not after it — run:

```bash
git fetch --prune origin
git switch -c <type>/<short-topic> origin/main
```

Do not carry on committing to whatever branch the working tree happened to be left on: it is
usually the *previous* session's, and once its pull request is merged the remote deletes it.
A hook refuses a commit on `main`, on a detached HEAD, and on a branch it can tell is stale —
but it never fetches, so it only knows what your last `git fetch --prune` left behind. That
is why the fetch above is on you, and why a silent pass is not evidence the branch is live.
The recovery recipe, if you are already on a stale branch, is in `.llmwiki/Hooks.md`.

- Branch names: `<type>/<short-topic>`, using the commit-message types below.
- Commit messages: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`.
- Do not commit build artifacts or generated files.
- Never force-push, and never rewrite a commit that is already on `origin/main`.
