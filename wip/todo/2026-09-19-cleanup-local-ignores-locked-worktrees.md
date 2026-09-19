# `cleanup_local.sh` promises to remove a locked worktree, then fails without saying why

- **Noted:** 2026-09-19 — cleaning up before the `ship-parallel` loop on the two visual-refresh entries
- **Theme:** hooks
- **Area:** tooling
- **Blocks release:** no

The dry run listed `.claude/worktrees/agent-a2db9a6e4a41a3ae8` (`feat/game-rules-seeds`,
pull request #105 merged) as `would remove`; `--apply` then printed `FAILED` for the
worktree and its branch, with no reason. The worktree was locked by Claude Code
(`.git/worktrees/<name>/locked`: `claude agent agent-a2db… (pid 51219 …)`), and that pid was
a live `claude` process — a session still open. `scripts/cleanup_local.sh` never reads the
lock (no `lock` anywhere in it), so the dry run cannot tell the orchestrator that the
worktree belongs to a running session.

**Fix:** in `scripts/cleanup_local.sh`, read `git worktree list --porcelain`'s `locked`
line. A lock whose pid is alive is a `keep` line naming the pid ("locked by a running
session"); a lock whose pid is gone is stale and can be removed with
`git worktree remove -f -f`, said as such in the dry run. `--apply` prints git's error
when a removal fails.

**Acceptance:**
- `hooks_selftest.sh` (local cleanup section): a merged worktree locked by a live pid is
  kept with that reason in the dry run; locked by a dead pid, it is listed and removed.
