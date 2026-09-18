# guard-bash.sh judges `git -C $W commit` against the main checkout

- **Noted:** 2026-09-18 — while committing docs/wiki-sync from a worktree agent
- **Theme:** tooling
- **Area:** hooks
- **Blocks release:** no

In a worktree on `docs/wiki-sync`, the command `W=<worktree path>; git -C $W commit -F - <<'EOF' …`
was refused with "committing directly on main". The same commit with the path spelled out
literally (`git -C /home/…/agent-… commit -F <file>`) went through. The guard apparently
cannot resolve a `-C` operand that is a shell variable set earlier on the same line and falls
back to the main checkout's branch — the refusal message then points at the wrong problem
(a branch switch the agent had already made). Possibly the same parse family as
fix/guard-cd-parse-failure; check whether that change covers it before fixing.

**Fix:** when the `-C` operand is not a literal path, refuse with a message that says so
("spell the path out"), rather than judging the main checkout's branch.

**Acceptance:**
- `scripts/hooks_selftest.sh` has a case for `W=<path>; git -C $W commit …` and the refusal,
  if any, names the unresolved operand rather than main.
