#!/bin/bash
# Plant a hardcoded French default for the Undo label, in the file the task edits.
set -euo pipefail
f=lib/utils/undo_snack_bar.dart
sed -i "s/required String undoLabel,/String undoLabel = 'Annuler',/" "$f"
grep -q "String undoLabel = 'Annuler'," "$f"
grep -q "Duration(seconds: 6)" "$f"
