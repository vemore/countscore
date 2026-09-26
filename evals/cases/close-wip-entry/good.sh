#!/bin/bash
# The right outcome, done by hand: selftest.sh expects check.sh to pass on it.
set -euo pipefail
sed -i -E 's/^21 entries\./12 entries./' wip/README.md
f=$(ls wip/todo/*-wip-readme-states-the-wrong-todo-cap.md)
git mv "$f" wip/done/
d="wip/done/$(basename "$f")"
sed -i "1a\\
\\
**Status:** done ($(date +%F)) — closed by eval. wip/README.md says 12 again." "$d"
git add -A
git commit -qm "docs: wip/README.md states the cap of 12" --no-verify
