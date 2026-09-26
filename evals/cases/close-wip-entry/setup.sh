#!/bin/bash
# Plant a wrong cap on wip/todo/ in wip/README.md, and the wip/todo/ entry that reports it.
set -euo pipefail
sed -i -E 's/^12 entries\./21 entries./' wip/README.md
grep -q '^21 entries\.' wip/README.md
cat > "wip/todo/$(date +%F)-wip-readme-states-the-wrong-todo-cap.md" <<'ENTRY'
# wip/README.md gives the wrong cap on wip/todo/

- **Noted:** while preparing a refinement pass
- **Theme:** docs
- **Area:** docs
- **Blocks release:** no

The Refinement section of `wip/README.md` says `todo/` holds at most 21 entries. The cap
decided at the 2026-09-18 refinement is 12.

**Fix:** say 12 in `wip/README.md`.

**Acceptance:**
- `grep -n "21 entries" wip/README.md` finds nothing, and the section says 12.
ENTRY
