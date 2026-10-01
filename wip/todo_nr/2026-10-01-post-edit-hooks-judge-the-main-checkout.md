# The two post-edit hooks judge the main checkout, not the worktree the edited file is in

- **Noted:** 2026-10-01 — auditing the hooks to write a reusable project bootstrap
- **Theme:** hooks
- **Area:** tooling
- **Blocks release:** no

`.llmwiki/Hooks.md:25` says "Every handler resolves the repository from the payload's `cwd`".
The two `PostToolUse` handlers do not: `guard-gitignore.sh:17` and `check-arb-sync.sh:21` both
set `ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"`, which is the main checkout whatever worktree the
`Edit` happened in.

- `guard-gitignore.sh` runs `git check-ignore --no-index` in the main checkout, so a worktree
  `.gitignore` that starts ignoring `web/sqlite3.wasm` is not reported at edit time. The commit
  gate in `guard-bash.sh` still refuses it (it judges the worktree), so nothing ships — the
  early warning is just silent.
- `check-arb-sync.sh` passes the edited worktree file as `--focus` but lets `arb_keys.py` read
  `l10n.yaml` and every other ARB from the main checkout (`check-arb-sync.sh:32`), so the drift
  it reports mid-translation compares the worktree's file against `main`'s locales: keys the
  branch already added elsewhere show as missing, and real drift can be hidden.

**Fix:** take `ROOT` from the edited file: `git -C "$(dirname "$file")" rev-parse
--show-toplevel`, falling back to `CLAUDE_PROJECT_DIR`; run `arb_keys.py` with that root.
Correct `.llmwiki/Hooks.md` if any handler is meant to keep the old behaviour.

**Acceptance:**
- A selftest case edits a `.gitignore` inside a worktree (launch checkout on `main`) so that it
  ignores `web/sqlite3.wasm`, and `guard-gitignore.sh` exits 2.
- A selftest case adds a key to two ARB files in a worktree and `check-arb-sync.sh` reports
  only the eight locales still missing it there, not the main checkout's state.
