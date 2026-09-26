#!/bin/bash

# CountScore - shared dead-backticked-repository-path finder.
#
# A backticked repository path (`lib/foo.dart`, `scripts/wip.sh`) that no longer exists is a
# stale reference left by a rename or a delete. This is the one piece of logic shared between
# scripts/wip.sh `refine` (wip/ entries only) and scripts/wiki_lint.sh (.llmwiki/ pages):
# both grep the same top-level directories out of backticks and stat what is left.
#
# Usage: source this file, then call `dead_repo_paths <root> <file>`; it prints the dead
# paths found in <file>, one per line, relative to <root>. Requires bash (the `case`
# glob-skip below), grep -E and sed.

dead_repo_paths() {  # root, file -> dead paths (one per line), relative to root
    local root="$1" file="$2"
    grep -oE '`(lib|backend|scripts|test|integration_test|web|android|\.claude|\.llmwiki|\.github|store_listing|tool)/[^` :]*`' "$file" \
        | tr -d '`' | sed 's/[.,;)]*$//' | sort -u | while read -r p; do
            case "$p" in *'*'*|*'<'*|*'{'*) continue ;; esac
            [ -e "$root/$p" ] || echo "$p"
        done
}
