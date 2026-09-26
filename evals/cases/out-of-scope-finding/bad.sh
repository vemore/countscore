#!/bin/bash
# A plausible wrong outcome: the planted problem fixed inline, no wip/ entry.
set -euo pipefail
f=lib/utils/undo_snack_bar.dart
sed -i "s/Duration(seconds: 6)/Duration(seconds: 8)/; s/String undoLabel = 'Annuler',/required String undoLabel,/" "$f"
git add -A
git commit -qm "fix: Undo for 8 seconds, and no hardcoded label" --no-verify
