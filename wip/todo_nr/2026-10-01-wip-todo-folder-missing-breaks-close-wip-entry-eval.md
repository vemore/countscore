# `wip/todo/` no longer exists, so the `close-wip-entry` eval fails before the agent starts

- **Noted:** 2026-10-01 — auditing the process tooling to write a reusable project bootstrap
- **Theme:** process-evals
- **Area:** tooling
- **Blocks release:** no

Git does not track empty directories. Once the last entry of `wip/todo/` was closed (latest
commit touching it: `452ecfd`, 2026-09-26), the folder disappeared from `origin/main` and from
every fresh worktree. `evals/cases/close-wip-entry/setup.sh` runs under `set -euo pipefail` and
writes `wip/todo/<date>-wip-readme-states-the-wrong-todo-cap.md` (`:6`) with no `mkdir`, so the
redirection fails and the case aborts at setup — the eval can no longer judge anything. Any
other tool or agent that writes the first entry of a release with a plain `cat >` hits the same
error. `scripts/wip.sh list todo` copes (it prints an empty list).

**Fix:** commit `wip/todo/.gitkeep` (and `wip/todo_nr/.gitkeep`, `wip/done/.gitkeep` for
symmetry), have `scripts/wip.sh` ignore `.gitkeep`, and add `mkdir -p wip/todo` to the eval's
`setup.sh` so the case does not depend on the state of `main`. Mention the placeholder in
`wip/README.md`.

**Acceptance:**
- `git ls-files wip/todo/.gitkeep` prints the path on `main`.
- `evals/run.sh --dry-run close-wip-entry` gets past setup and judges the untouched tree as
  `case.env` says.
- `scripts/wip.sh check all` and `list all` do not report the `.gitkeep` files.
