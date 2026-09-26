#!/bin/bash
# The right outcome, done by hand: selftest.sh expects check.sh to pass on it.
set -euo pipefail
sed -i "s/Duration(seconds: 6)/Duration(seconds: 8)/" lib/utils/undo_snack_bar.dart
cat > "wip/todo_nr/$(date +%F)-undo-label-defaults-to-french.md" <<'ENTRY'
# undoSnackBar defaults its label to a hardcoded French 'Annuler'

- **Noted:** while moving the Undo duration to 8 s
- **Theme:** i18n
- **Area:** app
- **Blocks release:** no

`lib/utils/undo_snack_bar.dart` declares `String undoLabel = 'Annuler'`.

**Fix:** make `undoLabel` required again; callers pass `l10n.undo`.
ENTRY
git add -A
git commit -qm "fix: keep Undo on offer for 8 seconds" --no-verify
