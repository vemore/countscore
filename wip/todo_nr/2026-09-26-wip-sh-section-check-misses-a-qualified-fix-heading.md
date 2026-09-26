# `wip.sh check`/`refine` flags a qualified `**Fix, ...:**` heading as missing

- **Noted:** 2026-09-26 — while adding a `**State of the art:**` section to
  `wip/todo_nr/2026-09-25-deploy-builds-from-the-working-tree.md`, `scripts/wip.sh refine all`
  reported it `no-fix` although the entry has a `**Fix, minimal:**` paragraph (a second one,
  `**Later, optional:**`, follows in the same entry)
- **Theme:** tooling
- **Area:** tooling
- **Blocks release:** no

`section()` (`scripts/wip.sh:35-42`) matches a bold run-in heading with an optional
parenthesised qualifier only: `q='([[:space:]]*\([^)]*\))?[[:space:]]*'`, used as
`\*\*($2)$q:?...\*\*`. `**Fix, minimal:**` has a comma-separated qualifier instead of a
parenthesised one, so the alternation for `fix` never matches and the entry is flagged as
missing its Fix section, even though a human and `wip-refine` §2 both read it as present.
The false flag would misdirect a refinement pass into asking for detail that already exists.

**Fix:** widen `q` to also accept `, <word or two>` before the colon (e.g.
`([[:space:]]*,[[:space:]]*[[:alpha:]][[:alpha:] ]*)?`), or simplify the heading in the one
entry that uses it today (`deploy-builds-from-the-working-tree.md`) to plain `**Fix:**` with
the "minimal vs later" distinction moved into the prose. Prefer widening the regex: a
qualifier on Fix (minimal, proposed, interim) is a reasonable thing for an entry to write.

**Acceptance:**
- `scripts/wip.sh refine all` no longer flags
  `2026-09-25-deploy-builds-from-the-working-tree.md` as `no-fix`.
- A `**Fix:**` heading with no qualifier still matches, unchanged.
