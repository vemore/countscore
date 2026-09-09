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
2. **Always pass `--no-tree-shake-icons`** to every build — apk, appbundle, ios and web.
   Game-type icons are built from database values, so the tree-shaker cannot see them and
   the build fails without it.
3. **A fresh clone does not compile until code is generated.** `*.g.dart` is gitignored:
   run `dart run build_runner build` first.
4. **Never commit** the keystore, `key.properties`, or any `.env`.
5. **`web/sqlite3.wasm` and `web/drift_worker.js` are tracked on purpose** — do not delete
   or gitignore them. See `.llmwiki/Web.md`.

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
- **Nothing is finished until it is tested and committed.** A feature or a bugfix is done
  only once the automated gates covering the code it touches are green *and* the change is
  committed. For the Flutter app that gate is imperative: **`flutter analyze && flutter
  test` must pass before committing** — no exception, whatever the change. For `backend/`
  it is `ruff check`, `mypy` and `pytest` (see `backend/CLAUDE.md`). Green gates with no
  commit, or a commit with no green gates, are both incomplete.

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

Do not carry on committing to whatever branch the working tree happened to be left on. That
branch is usually the *previous* session's, and once its pull request is merged the remote
rebases and deletes it: committing there stacks new work on top of commits that no longer
exist upstream, and the branch has to be untangled before anything can be pushed. The
starting branch being clean is not evidence that it is still live — check `git branch -r`.

If you find you have already committed to a stale branch, recover it rather than rewriting
history: `git cherry -v origin/main HEAD` marks commits already upstream with `-` and genuinely
new ones with `+`; branch off `origin/main` and cherry-pick only the `+` ones.

- Branch names: `<type>/<short-topic>`, using the commit-message types below.
- Commit messages: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`.
- Do not commit build artifacts or generated files.
- Never force-push, and never rewrite a commit that is already on `origin/main`.
