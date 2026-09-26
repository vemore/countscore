#!/bin/bash

# CountScore - self-test for scripts/wiki_lint.sh.
#
# Builds a throwaway fixture wiki with one instance of each finding and one clean
# counter-example for it, then checks the report names exactly what it should. The dead-path
# check still resolves against this repository's real root (like scripts/wip.sh `refine`,
# whose pattern it shares) — the fixture pages reference a script that really exists
# (scripts/wiki_lint.sh) and a path that really does not, rather than faking a checkout.
#
# Usage: scripts/wiki_lint_selftest.sh      (exit 0 = every case holds)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINT="$ROOT/scripts/wiki_lint.sh"

pass=0
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

report() {  # description, expected (0 or 1), actual
    if { [ "$2" = present ] && [ "$3" = 1 ]; } || { [ "$2" = absent ] && [ "$3" = 0 ]; }; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        printf '  FAIL  %s (expected %s, matched %s time(s))\n' "$1" "$2" "$3"
    fi
}

wiki="$tmp/wiki"
mkdir -p "$wiki"

cat > "$wiki/INDEX.md" <<'EOF'
# Index

`[[Name]]` resolves to `.llmwiki/Name.md`, same convention as the real INDEX.md — this
`[[Placeholder]]` here must not be read as a dead link.

| Page | Summary | Updated |
|---|---|---|
| [[Short]] | a clean page, nothing to report | 2026-01-01 |
| [[Long]] | over the line budget | 2026-01-02 |
| [[Stale]] | its own Updated: disagrees with this row | 2026-01-03 |
| [[HasLink]] | carries one of every other finding | 2026-01-04 |
EOF

cat > "$wiki/Short.md" <<'EOF'
# Short

> Updated: 2026-01-01

A page with nothing for the linter to find.
EOF

{
    echo "# Long"
    echo
    echo "> Updated: 2026-01-02"
    echo
    seq 1 410 | sed 's/^/line /'
} > "$wiki/Long.md"

cat > "$wiki/Stale.md" <<'EOF'
# Stale

> Updated: 2026-01-09

INDEX.md's row for this page says 2026-01-03; this line says otherwise.
EOF

cat > "$wiki/HasLink.md" <<'EOF'
# HasLink

> Updated: 2026-01-04

Links to [[Short]] (lives) and to [[Ghost]] (does not — a dead link). A backticked
example like `[[Placeholder]]` is not a link to resolve, same as INDEX.md's own convention
text.

> **Status: Outdated** (2026-01-01) — this block was never folded back.

Mentioning the marker itself, `Status: Outdated`, in prose is not a block and must not
match.

References `scripts/wiki_lint.sh`, which exists, and
`lib/definitely_missing_file_xyz.dart`, which does not.
EOF

out=$("$LINT" "$wiki" 2>&1)
n() { grep -Fc "$1" <<< "$out"; }        # occurrences of a literal string in the report
nre() { grep -Ec "$1" <<< "$out"; }      # occurrences of a regex in the report

echo "== findings that must appear ===================================="
report "the over-budget page"       present "$(n 'Long.md: 41')"
report "the stale INDEX.md date"    present "$(n 'INDEX.md: row for [[Stale]] says 2026-01-03, Stale.md says 2026-01-09')"
report "the dead link"              present "$(n 'HasLink.md:5: dead link [[Ghost]]')"
report "the status block"           present "$(n 'HasLink.md:9: Status: Outdated block (2026-01-01)')"
report "the dead backticked path"   present "$(n 'HasLink.md: dead path `lib/definitely_missing_file_xyz.dart`')"

echo "== findings that must not appear ================================="
report "the clean page"                    absent "$(n 'Short.md:')"
report "the backticked [[Placeholder]] example (INDEX.md)" absent "$(n 'dead link [[Placeholder]]')"
report "the backticked [[Name]] example (INDEX.md)"        absent "$(n 'dead link [[Name]]')"
report "the live link [[Short]] from HasLink.md"           absent "$(n 'dead link [[Short]]')"
report "the live backticked path"                          absent "$(n 'dead path `scripts/wiki_lint.sh`')"
report "the prose mention of the marker, not a real block" absent "$(n 'HasLink.md:11')"
report "INDEX.md itself against the page budget"           absent "$(nre '^INDEX\.md: [0-9]+ lines, over the 400 budget$')"

echo "== exit code and contract ========================================"
"$LINT" "$wiki" > /dev/null 2>&1
code=$?
report "non-zero exit with findings present" present "$([ "$code" -ne 0 ] && echo 1 || echo 0)"

clean="$tmp/clean"
mkdir -p "$clean"
cp "$wiki/Short.md" "$clean/Short.md"
cat > "$clean/INDEX.md" <<'EOF'
# Index

| Page | Summary | Updated |
|---|---|---|
| [[Short]] | a clean page, nothing to report | 2026-01-01 |
EOF
"$LINT" "$clean" > /dev/null 2>&1
code=$?
report "zero exit on a wiki with no finding" present "$([ "$code" -eq 0 ] && echo 1 || echo 0)"

if [ -x "$LINT" ]; then
    pass=$((pass + 1))
else
    fail=$((fail + 1))
    echo "  FAIL  $LINT is not executable"
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
