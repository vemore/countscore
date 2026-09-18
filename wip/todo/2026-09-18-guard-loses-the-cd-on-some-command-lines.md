# The commit guard sometimes judges the main checkout instead of the worktree the command cd's into

- **Noted:** 2026-09-18 — moving a wip entry from a worktree
- **Theme:** hooks
- **Area:** tooling
- **Blocks release:** no

`guard-bash.sh` refused as "committing directly on main" a command line of the shape
`cd ../countscore-wip-move && git commit -q -F - <<'EOF' … EOF` followed, on the next lines, by
`git push … | grep -v remote; gh pr create … --body "$(printf '…'"'"'…')"`. The worktree
was on `docs/wip-move-planned-review`. The same `cd … && git commit -F - <<'EOF'` shape passed
an hour earlier (#87) when followed by a plain `gh pr create --body "$(cat <<'EOF' … EOF)"`, so
the suspect is the `'"'"'` quoting or the pipe making `parse_command.py` lose the `cd` and fall
back to `CLAUDE_PROJECT_DIR`. Not confirmed. `git -C <worktree> commit` passed at once.

The refusal is safe (it blocks, never lets through), but its message sends you to recover a
stale branch that does not exist.

**Fix:** reproduce the line in `scripts/hooks_selftest.sh`; if the parser cannot follow the
`cd`, have it say so ("could not tell which repository this runs in — use `git -C`") rather
than judging the main checkout.

**Cause confirmed (2026-09-18, refinement):** `.claude/hooks/parse_command.py:477-484` — when
`tokenize()` fails, the commit verdict takes the payload's cwd, so the `cd` is never followed.

**Acceptance:**
- A `hooks_selftest.sh` case reproducing the #88 command line no longer yields "committing directly on main".
- When parsing fails and the line has a `cd`, the refusal says it could not tell the repository and suggests `git -C`.
- Every existing selftest case still passes.
