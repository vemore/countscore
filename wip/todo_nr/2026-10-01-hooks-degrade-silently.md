# The hooks degrade without a word: no `jq` or `python3` turns every guard off, and the Stop hook misses staged and untracked leftovers

- **Noted:** 2026-10-01 — auditing the hooks to write a reusable project bootstrap
- **Theme:** hooks
- **Area:** tooling
- **Blocks release:** no

1. **Fail-open with no message.** `guard-bash.sh:21` exits 0 when `parse_command.py` prints
   nothing — which is what happens when `python3` is missing — and every later decision goes
   through `jq` (`:30`, `:42`, `:50`, `:60`): without `jq`, `blocked` is empty and
   `jq -e '.commit != null' || exit 0` skips the gates. Failing open on the hook's *own* bug is
   deliberate (`.llmwiki/Hooks.md` § Decisions), but a missing dependency is not a bug, and
   nothing tells the session that force-push, push-to-main and the commit gates are off. A
   fresh machine or a cloud container without `jq` would run unguarded.
2. **The Stop hook's "commit the remaining changes first"** is built from
   `git diff --quiet` (`require-pull-request.sh:75`), which ignores staged changes and untracked
   files — the two states a half-finished agent most often leaves behind.

**Fix:** `session-start.sh` checks `command -v python3 jq gh` and prints, when one is missing,
which guards are off and how to install it; `require-pull-request.sh` uses
`git status --porcelain` for the leftover test.

**Acceptance:**
- With `jq` hidden from `PATH`, `session-start.sh` prints a line naming `jq` and the guards it
  disables; with everything present it prints nothing new.
- A selftest case with only a staged change (and one with only an untracked file) on a branch
  with no pull request gets the "commit the remaining changes first" sentence.
