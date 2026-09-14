#!/bin/bash

# CountScore - read the wip/ work tracker.
#
# There is deliberately no index file under wip/: a shared index is the conflict
# that wip/ exists to remove. This builds the view from the entries themselves.
#
# Usage: scripts/wip.sh [list] [todo|todo_nr|done|all]   entries, grouped by theme
#        scripts/wip.sh themes [todo|todo_nr|all]         themes with their entry count
#        scripts/wip.sh check                             entries missing a header field
#
# Default: list todo.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIP="$ROOT/wip"

cmd="${1:-list}"
case "$cmd" in list|themes|check) shift || true ;; *) cmd=list ;; esac
scope="${1:-todo}"
case "$scope" in
    all) dirs=(todo todo_nr done) ;;
    todo|todo_nr|done) dirs=("$scope") ;;
    *) echo "unknown scope: $scope (todo, todo_nr, done, all)" >&2; exit 2 ;;
esac

field() {  # file, field name
    sed -n "s/^- \*\*$2:\*\* *//p" "$1" | head -1
}

rows() {  # prints: folder<TAB>theme<TAB>blocks<TAB>area<TAB>file<TAB>title
    local folder file
    for folder in "${dirs[@]}"; do
        for file in "$WIP/$folder"/*.md; do
            [ -e "$file" ] || continue
            case "$(basename "$file")" in ARCHIVE-*) continue ;; esac
            printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$folder" \
                "$(field "$file" Theme | cut -d' ' -f1)" \
                "$(field "$file" 'Blocks release')" \
                "$(field "$file" Area)" \
                "${file#"$ROOT"/}" \
                "$(sed -n 's/^# //p' "$file" | head -1)"
        done
    done
}

case "$cmd" in
    list)
        rows | sort -t$'\t' -k1,1 -k2,2 -k5,5 | awk -F'\t' '
            $1 != folder { if (folder != "") print ""; folder = $1; theme = ""; print "wip/" folder "/" }
            $2 != theme  { theme = $2; print "  [" (theme == "" ? "no theme" : theme) "]" }
            { flag = ($3 ~ /^yes/) ? "!" : " "; printf "   %s %-8s %s\n       %s\n", flag, $4, $6, $5 }'
        echo
        echo "! = blocks the release"
        ;;
    themes)
        rows | awk -F'\t' '{ n[$1 "\t" $2]++ } END { for (k in n) print k "\t" n[k] }' | sort \
            | awk -F'\t' '{ printf "%-8s %-28s %d\n", $1, ($2 == "" ? "(none)" : $2), $3 }'
        ;;
    check)
        status=0
        rows | while IFS=$'\t' read -r folder theme blocks area file title; do
            missing=""
            [ -z "$title" ] && missing="$missing title"
            [ -z "$theme" ] && missing="$missing Theme"
            [ -z "$area" ] && missing="$missing Area"
            [ "$folder" != done ] && [ -z "$blocks" ] && missing="$missing Blocks-release"
            [ "$folder" = done ] && ! grep -q '^\*\*Status:\*\* done' "$ROOT/$file" && missing="$missing Status"
            [ -n "$missing" ] && echo "$file: missing$missing"
        done | tee /dev/stderr | grep -q . && status=1
        exit $status
        ;;
esac
