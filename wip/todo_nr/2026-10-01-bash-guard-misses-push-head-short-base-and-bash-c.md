# The Bash guard lets three refused shapes through: `push origin HEAD` on main, `gh pr create -B`, and anything inside `bash -c`

- **Noted:** 2026-10-01 — auditing the hooks to write a reusable project bootstrap
- **Theme:** hooks
- **Area:** tooling
- **Blocks release:** no

Each was reproduced by piping a payload into `.claude/hooks/parse_command.py` from the main
checkout, on `main`:

| Command | Blocks returned | Should be |
|---|---|---|
| `git push origin HEAD` | none — `push.refspecs` is `["HEAD"]` | `push-main` while on `main` |
| `gh pr create -B feat/x --fill` | none | `stacked-pr` |
| `bash -c 'git push --force origin x'` | none | `force-push` |
| `git push --force origin x` (control) | `force-push` | — |

- `guard-bash.sh:50` treats only a *bare* push (empty refspecs) as a push to the current
  branch; a `HEAD` or `@` refspec is not resolved to it, and `parse_command.py:373` only
  matches a destination spelled `main`.
- `parse_command.py:268` reads `--base` only; the short `-B` is never parsed.
- `normalize_head` strips `env`, `sudo`, `nohup`… but never unwraps `bash -c`, `sh -c` or
  `eval`, so every rule is bypassed by wrapping the command in a string. The local allowlist
  holds `Bash(bash:*)`, so such a line runs without a prompt.

None of these was hit in practice; they are holes in a guard whose whole value is that the
owner's token can otherwise do all three (`.llmwiki/ParallelDelivery.md` § protection,
`enforce_admins: false`).

**Fix:** in `guard-bash.sh`, resolve a `HEAD` / `@` / `HEAD:<x>`-less refspec to the branch of
the repository the push runs in before the `push-main` test; accept `-B <x>` (and bundled
forms) in the `stacked-pr` rule; in `parse_command.py`, parse the string argument of
`bash|sh|zsh -c` and `eval` recursively, with the same cwd, and merge its blocks and
commit/push verdicts.

**Acceptance:**
- `scripts/hooks_selftest.sh` refuses `git push origin HEAD` and `git push origin @` from
  `main`, and passes them from a feature branch.
- It refuses `gh pr create -B feat/x` and passes `gh pr create -B main`.
- It refuses `bash -c 'git push --force origin x'` and `sh -c "gh pr merge 1 --admin"`, and
  passes `bash -c 'echo git push --force'`.
