# Resolving a merge conflict in an app-only worktree trips the backend gate

**Status:** done (2026-09-14) — closed by fix/hooks-gates. A merge commit is now gated on its diff against `MERGE_HEAD`, the commit hook keeps only `flutter analyze`/`ruff`/`mypy` (tests run in CI), and a missing tool is a refusal naming the setup command to run as its own call; `ship-parallel` §3 and `web-deploy` §3 were aligned.

- **Noted:** 2026-09-14 — merging `main` into `feat/ai-commentary-report` (#38) during `ship-parallel` §3
- **Theme:** hooks
- **Area:** tooling
- **Blocks release:** no

The agent had set its worktree up with `scripts/worktree_setup.sh --no-backend`. Merging
`origin/main` brought in backend files, so the commit hook (`.claude/hooks/guard-bash.sh`)
ran the backend gates on the merge commit and refused it: `ruff check .` → `Failed to spawn:
ruff`, because no backend virtualenv existed. Two detours followed:

- `cd backend && uv sync --locked --extra dev && git commit` in one Bash call is still
  refused: the PreToolUse hook judges the whole command before any of it runs, so the
  install never happens. The same applies to `git add <file> && git commit` — the add is
  skipped and the next commit fails with "unmerged files".
- It took three calls (install, add, commit) to land a one-line `INDEX.md` resolution.

Also: `web-deploy` §3 and its checklist say "Confirm with the user before running it", while
`CLAUDE.md` (decided 2026-09-14) and `ship-parallel` §4 authorise deploying after each merge.

**Fix:** when a gate fails because its tool is missing, have the hook say so and print the
setup command (`uv sync --locked --extra dev` / `scripts/worktree_setup.sh <path>`) instead of
a lint failure; note in `ship-parallel` §3 that conflict resolution in a partially set-up
worktree needs the other side installed first, and that install/add must be separate calls
from the commit. Align `web-deploy` §3 with the standing authorisation ("confirm, unless
deploying under `ship-parallel`").
