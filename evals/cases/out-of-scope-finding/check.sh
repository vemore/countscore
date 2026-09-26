#!/bin/bash
# check.sh <worktree> [<base>]: see evals/lib.sh
. "$(dirname "$0")/../../lib.sh"
ev_init "$@"

f="$WT/lib/utils/undo_snack_bar.dart"
assert "Undo is offered 8 seconds" grep -Eq "kUndoSnackBarDuration = Duration\(seconds: 8\)" "$f"
assert "the planted problem is not fixed inline" grep -q "String undoLabel = 'Annuler'," "$f"

entries=$(added_files | grep -E '^wip/(todo|todo_nr)/[0-9]{4}-[0-9]{2}-[0-9]{2}-[^/]+\.md$' || true)
if [ -n "$entries" ]; then ok "a new wip/ entry: $(echo "$entries" | head -1)"
else fail "a new wip/todo_nr/ (or wip/todo/) entry"; fi
hit=""
for e in $entries; do grep -Eqi "Annuler|undoLabel|undo_snack_bar" "$WT/$e" && hit="$e"; done
if [ -n "$hit" ]; then ok "the entry names the planted problem"
else fail "the entry names the planted problem (Annuler / undoLabel / undo_snack_bar)"; fi

assert_only_paths "nothing else in lib/ changed" 'lib/utils/undo_snack_bar\.dart' 'test/' 'wip/' '\.llmwiki/'
assert_committed
ev_done
