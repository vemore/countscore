# The commit hook ignores git worktrees

**Status:** done (2026-09-14) — closed by `chore/parallel-delivery`. `parse_command.py` reports the directory each `git commit` / `git push` runs in (following `cd` and `git -C`); `guard-bash.sh`, `require-pull-request.sh` and `session-start.sh` resolve the repository from it, falling back to `CLAUDE_PROJECT_DIR`. `scripts/hooks_selftest.sh` commits from a worktree whose branch differs from the launch checkout's.

- **Noted:** 2026-09-13 — while committing `fix/sync-contract`; hit again 2026-09-13 and 2026-09-14
- **Theme:** hooks
- **Area:** tooling

`guard-bash.sh` resolved the repository as `$CLAUDE_PROJECT_DIR`, the directory the session
was launched in. A commit inside a worktree was judged on the main checkout's branch (refused
as "stale" when that branch was merged), and gated on the main checkout's files — or on
nothing, when it had nothing staged, so no gate ran at all. Two sessions could not use
worktrees to stay out of each other's way.
