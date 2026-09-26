#!/bin/bash

# CountScore - mechanical lint pass for .llmwiki/.
#
# .llmwiki/Documentation.md ("Wiki lint") splits the pruning pass run by hand before each
# release (release-android §3b) into a mechanical half and a judgement half. This script is
# the mechanical half:
#   - a page over the 400-line budget INDEX.md sets
#   - a `> **Status: Outdated**` block, which should have been folded back into the fact
#     it sits under
#   - a backticked repository path that no longer exists (scripts/lib/dead_paths.sh, shared
#     with scripts/wip.sh `refine`)
#   - a `[[Wiki link]]` naming a page `.llmwiki/<Name>.md` does not have
#   - an INDEX.md row whose date differs from the page's own `> Updated:` line
#
# Judgement is not attempted here: orphaned pages, a page whose Updated: predates the last
# commit to what it cites, contradictions between two pages, and whether a status block is
# actually older than the last release all still want a person. See .llmwiki/Documentation.md.
#
# This is a report, not a gate: it is expected to exit non-zero on the real wiki today (six
# pages over budget, dozens of status blocks not yet folded back) — see
# scripts/wiki_lint_selftest.sh for what is pinned in CI instead.
#
# Usage: scripts/wiki_lint.sh [wiki-dir]      (default: .llmwiki)
#        exit 0 = no finding, 1 = at least one finding

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib/dead_paths.sh"

WIKI="${1:-$ROOT/.llmwiki}"
WIKI="$(cd "$WIKI" && pwd)"
INDEX="$WIKI/INDEX.md"
BUDGET=400

findings=0

finding() {  # page, message
    printf '%s: %s\n' "$1" "$2"
    findings=$((findings + 1))
}

[ -f "$INDEX" ] || { echo "no INDEX.md under $WIKI" >&2; exit 2; }

for page in "$WIKI"/*.md; do
    name="$(basename "$page" .md)"

    # A page over the line budget. INDEX.md itself is the index, not a page — its own
    # budget is one line per row, checked separately below.
    if [ "$name" != INDEX ]; then
        lines=$(wc -l < "$page")
        [ "$lines" -gt "$BUDGET" ] && finding "$name.md" "$lines lines, over the $BUDGET budget"
    fi

    # `Status: Outdated` blocks never folded back into the fact they sit under. Anchored on
    # the convention in INDEX.md: `> **Status: Outdated** (YYYY-MM-DD) — ...`, any amount of
    # leading blockquote/list indent. This also matches the two worked examples in
    # INDEX.md and Documentation.md only if someone ever writes a real date in them — a
    # literal `YYYY-MM-DD` never matches \d{4}-\d{2}-\d{2}.
    while IFS=: read -r lineno rest; do
        [ -n "$lineno" ] || continue
        date=$(echo "$rest" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
        finding "$name.md:$lineno" "Status: Outdated block ($date)"
    done < <(grep -noE '^[[:space:]]*> \*\*Status: Outdated\*\* \([0-9]{4}-[0-9]{2}-[0-9]{2}\)' "$page")

    # A backticked repository path this page names that no longer exists.
    while read -r p; do
        [ -n "$p" ] || continue
        finding "$name.md" "dead path \`$p\`"
    done < <(dead_repo_paths "$ROOT" "$page")

    # A [[Wiki link]] naming a page .llmwiki/<Name>.md does not have. Skipped when the
    # brackets touch a backtick on either side: INDEX.md's and Documentation.md's own
    # convention text writes `[[Name]]`, `[[Link]]`, `[[Other]]` etc. as placeholders, not
    # as links to resolve.
    while IFS=: read -r lineno linkname; do
        [ -n "$lineno" ] || continue
        [ -f "$WIKI/$linkname.md" ] && continue
        finding "$name.md:$lineno" "dead link [[$linkname]]"
    done < <(perl -ne 'while (/(?<!`)\[\[([A-Za-z0-9_]+)\]\](?!`)/g) { print "$.:$1\n" }' "$page")
done

# An INDEX.md row whose date differs from the page's own `> Updated:` line.
while IFS='|' read -r _ link _summary date _; do
    linkname=$(echo "$link" | sed -n 's/.*\[\[\([A-Za-z0-9_]*\)\]\].*/\1/p')
    [ -n "$linkname" ] || continue
    date=$(echo "$date" | tr -d '[:space:]')
    page="$WIKI/$linkname.md"
    [ -f "$page" ] || continue  # a dead link, already reported above
    page_date=$(grep -m1 -E '^> Updated: ' "$page" | sed -E 's/^> Updated: *//')
    if [ "$date" != "$page_date" ]; then
        finding "INDEX.md" "row for [[$linkname]] says $date, $linkname.md says ${page_date:-nothing}"
    fi
done < <(grep -E '^\| \[\[' "$INDEX")

echo
echo "$findings finding(s)"
[ "$findings" -eq 0 ]
