# cleanup_local.sh keeps merged branches when gh is missing

- **Noted:** 2026-09-24 — while shipping feat/board-skull-sounds-timer from a cloud container
- **Theme:** hooks
- **Area:** tooling
- **Blocks release:** no

`scripts/cleanup_local.sh` proves a squash-merged branch merged only through `gh pr list
--state merged` (`scripts/cleanup_local.sh:60`, `:86`). Without `gh`, as in a claude.ai cloud
container where GitHub is reached through the MCP tools instead, every worktree and branch
whose pull request already merged is kept with the reason "N commit(s) ahead, and gh is
unavailable to prove they merged" (`:83`). On 2026-09-24 the orchestrator had to remove
them by hand after the parallel wave, which is the very step the script exists to make safe.

**Fix:** a git-only fallback when `gh` is missing: a branch whose tree matches the tree of a
squash commit on `origin/main` (`git log --format='%H %T' origin/main` against
`git rev-parse <branch>^{tree}`, or `git cherry`-style patch-id matching), or whose remote
branch was deleted by `git fetch --prune` after a merge, counts as merged. Or, smaller: a
`--merged <branch>` override that the caller, who saw the merge through another tool, passes
explicitly. Either keeps the script's current refusal for an unproven branch.

**Acceptance:**
- With `gh` absent from `PATH`, a branch whose squash commit is on `origin/main` is listed for removal, and `--apply` removes its worktree and branch.
- A branch with a commit that is not on `origin/main` is still kept, with its reason.
- `scripts/hooks_selftest.sh` (or a selftest of its own) covers both cases without network.
