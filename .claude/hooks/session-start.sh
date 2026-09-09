#!/bin/bash

# CountScore - session opener (Claude Code SessionStart hook)
#
# SessionStart is one of the few events whose plain stdout is injected into the
# conversation, so this says the two things that are only actionable BEFORE work
# starts: whether the clone still needs code generation, and whether the branch
# left over from the previous session is safe to commit on.

set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$ROOT" 2>/dev/null || exit 0

if [ -z "$(find lib -name '*.g.dart' -print -quit 2>/dev/null)" ]; then
    echo "Generated code is missing: run \`dart run build_runner build\` before anything else"
    echo "(no --delete-conflicting-outputs -- build_runner 2.16 removed the flag). Nothing compiles until then."
fi

git rev-parse --git-dir >/dev/null 2>&1 || exit 0
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
[ -z "$branch" ] && exit 0

if git rev-parse --verify -q origin/main >/dev/null 2>&1; then
    counts=$(git rev-list --left-right --count origin/main...HEAD 2>/dev/null)
    behind=$(echo "$counts" | cut -f1)
    ahead=$(echo "$counts" | cut -f2)
    track=$(git for-each-ref --format='%(upstream:track)' "refs/heads/$branch" 2>/dev/null)
    stale=""
    [ "$track" = "[gone]" ] && stale="its remote branch was merged and deleted"
    if [ -z "$stale" ] && [ "${ahead:-0}" -gt 0 ] && [ "${ahead:-0}" -le 50 ]; then
        git cherry origin/main HEAD 2>/dev/null | grep -q '^-' \
            && stale="it replays commits already on origin/main"
    fi
    echo "Branch: $branch (${ahead:-0} ahead, ${behind:-0} behind origin/main)"
    if [ "$branch" = "main" ] || [ -n "$stale" ]; then
        [ -n "$stale" ] && echo "This branch is not safe to commit on -- $stale."
        echo "Start the session's work on a fresh branch:"
        echo "  git fetch --prune origin && git switch -c <type>/<short-topic> origin/main"
    fi
fi
exit 0
