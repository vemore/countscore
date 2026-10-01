# `gh pr merge --delete-branch` errors after a successful merge whenever the branch has a worktree

- **Noted:** 2026-10-01 — merging #241 from the main checkout, its branch held by `../countscore-wip-hook-gaps`
- **Theme:** merge-safety
- **Area:** tooling
- **Blocks release:** no

`ship-parallel` §3.6 merges with `gh pr merge <n> --squash --delete-branch`
(`.claude/skills/ship-parallel/SKILL.md:234`). After the squash merge succeeds, gh tries to
delete the local branch too, and in this project every pull request's branch is checked out in
a worktree (an agent's, or `../countscore-<topic>`). #241 printed:

    failed to delete local branch docs/wip-hook-gaps: failed to run git: error: cannot delete
    branch 'docs/wip-hook-gaps' used by worktree at '/home/vemore/workspace/countscore-wip-hook-gaps'

The merge itself had landed, so the step reads as a failure that is not one. Run from inside
the worktree instead, gh first switches it to `main` — which the main checkout already holds —
and fails the same way. Newer gh releases (cli/cli#13955) instead remove the sibling worktree,
which would pull a tree from under an agent that may still be reporting.

`--delete-branch` adds nothing here: the repository has `deleteBranchOnMerge: true`
(`.llmwiki/ParallelDelivery.md` § protection table), so GitHub deletes the remote branch, and
`scripts/cleanup_local.sh` removes the local branch and worktree once it can prove the merge.

**Fix:** drop `--delete-branch` from `ship-parallel` §3.6; the hook keeps accepting both forms.

**Acceptance:**
- `grep -rn -- '--delete-branch' .claude/skills .llmwiki CLAUDE.md` finds no instruction to use it.
- A `ship-parallel` merge of a pull request whose branch has a worktree prints no error.
