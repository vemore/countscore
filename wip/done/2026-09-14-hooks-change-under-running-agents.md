# Parallel agents share the main checkout's hooks, which a merge changes under them

**Status:** done (2026-09-14) — closed by fix/hooks-gates. `ship-parallel` §1 now merges a pull request touching `.claude/` last in its wave, once every agent has reported; tracking the hooks' commit per session was rejected as more process.

- **Noted:** 2026-09-14 — while reviewing the two weeks of work since 2026-09-09
- **Theme:** hooks
- **Area:** tooling
- **Blocks release:** no

Hooks are loaded from `${CLAUDE_PROJECT_DIR}/.claude/hooks`, the main checkout, and
`ship-parallel` §3 fast-forwards that checkout after every merge. An agent launched before a
merge that changes a hook is judged, mid-task, by rules it never read — the failure
`.llmwiki/ParallelDelivery.md` records for 2026-09-14, in the other direction. At the time of
this note five agent worktrees under `.claude/worktrees/` held uncommitted changes from
another session, so the situation is the normal case, not an edge. `scripts/cleanup_local.sh`
(#34) tidies up afterwards but does not prevent it.

**Fix:** either do not merge a pull request that touches `.claude/hooks/` while agents of a
wave are still running (say so in `ship-parallel` §1 ordering: tooling pull requests merge
last, or in their own wave), or have `session-start.sh` record the hooks' commit and
`guard-bash.sh` warn when the main checkout's hooks changed since the session started.
