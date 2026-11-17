# worktree_setup.sh skips the backend silently when uv is not installed

- **Noted:** 2026-11-17 — setting up the worktree for feat/max-rounds-chouineurs
- **Theme:** tooling
- **Area:** tooling
- **Blocks release:** no

`scripts/worktree_setup.sh` runs `uv sync --locked --extra dev` only
`if command -v uv` (line 76), and says nothing when it is absent. On this machine `uv` is not
on PATH, so the worktree came up "ready" with no `backend/.venv`: backend `pytest` could not
run, and the commit hook (`.claude/hooks/guard-bash.sh`, the `backend/` gate) refuses any
commit touching `backend/` until ruff and mypy exist there. The detour was installing `uv`
into a scratch venv with pip and running `uv sync` by hand.

**Fix:** when the backend is wanted and `uv` is missing, print a line saying the backend venv
was not built and how to get `uv` (or fall back to `python3 -m pip install uv` into a venv the
script owns). Prefer the warning to a new rule.

**Acceptance:**
- On a machine without `uv`, `scripts/worktree_setup.sh <dir>` prints that the backend venv
  was skipped, and why.
