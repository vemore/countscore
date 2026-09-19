# A branch cannot add an ARB exemption: the commit hook reads the main checkout's list

- **Noted:** 2026-09-18 — adding the board's strings on `feat/board-lanes`
- **Theme:** hooks
- **Area:** tooling
- **Blocks release:** no
- **Status:** done (2026-09-19) — closed by fix/arb-hook-branch-exemptions. `guard-bash.sh` runs `$ROOT/.claude/hooks/arb_keys.py` when the committed tree has one, falling back to its own; two `hooks_selftest.sh` cases prove the tree's checker is the one that runs. It blocked the merge of `main` into `feat/score-keypad` (#124).

`.claude/hooks/guard-bash.sh:17` sets `HOOKS` to the directory of the hook that runs, which
is the **main checkout's** `.claude/hooks/`, and runs `$HOOKS/arb_keys.py --values` against
the worktree's ARB files (`guard-bash.sh:195`). So `SAME_AS_ENGLISH_OK` comes from `main`,
not from the branch being committed. A branch that adds a key whose translation equals the
English one — "Total" in French, Spanish and Portuguese — and adds the matching exemption in
the same change, as the `i18n-add-string` skill says to, is refused at commit anyway; the
exemption only takes effect once it is merged. `feat/board-lanes` had to pick other words
("Points", "Puntos", "Pontos", "Rd.{number}", "M{number}") to get past it.

**Fix:** run the `arb_keys.py` of the repository being committed (`$ROOT/.claude/hooks/`)
when it exists, falling back to `$HOOKS`; or move `SAME_AS_ENGLISH_OK` to a data file under
`lib/l10n/` that the script reads from `CLAUDE_PROJECT_DIR`.

**Acceptance:**
- In a worktree, adding a key equal to English in `fr` plus its `SAME_AS_ENGLISH_OK` entry
  commits; the same key without the entry is refused.
