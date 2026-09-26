#!/bin/bash
# A plausible wrong outcome: the fix made, the entry deleted instead of moved and closed.
set -euo pipefail
sed -i -E 's/^21 entries\./12 entries./' wip/README.md
git add -A
git rm -q wip/todo/*-wip-readme-states-the-wrong-todo-cap.md
git commit -qm "docs: fix the todo cap" --no-verify
