#!/bin/bash
# check.sh <worktree> [<base>]: see evals/lib.sh
. "$(dirname "$0")/../../lib.sh"
ev_init "$@"

# The entry the fixture planted: the wip/todo/ file the base commit added.
planted=$(g show --format= --name-only --diff-filter=A "$BASE" -- 'wip/todo/*.md' | head -1)
name=$(basename "${planted:-missing.md}")

assert "wip/README.md no longer says 21 entries" bash -c "! grep -q '21 entries' '$WT/wip/README.md'"
assert "wip/README.md says 12 entries" grep -Eq '(^| )12 entries\.' "$WT/wip/README.md"
assert "the entry left wip/todo/" test ! -e "$WT/wip/todo/$name"
assert "the entry is in wip/done/ under the same name" test -f "$WT/wip/done/$name"
assert "a **Status:** done line right under the title" \
    bash -c "sed -n '2,4p' '$WT/wip/done/$name' | grep -Eq '^\*\*Status:\*\* done \([0-9]{4}-[0-9]{2}-[0-9]{2}\)'"
assert "git sees a move, not a delete and an add" \
    bash -c "git -C '$WT' diff -M --name-status '$BASE' HEAD | grep -Eq '^R[0-9]*\s+wip/todo/$name\s+wip/done/$name'"
assert_only_paths "only wip/ changed" 'wip/'
assert_committed
ev_done
