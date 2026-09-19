#!/bin/bash

# CountScore - self-test of scripts/check_web_build.sh.
#
# That script is the last thing between build/web/ and a public URL, for both
# publishing paths (deploy_web.sh and the GitHub Pages workflow). A check that
# silently stopped refusing would publish the next stray note, so its refusals are
# pinned here against fixture builds. Needs neither Flutter nor the network; the
# `app` CI job runs it next to the hooks self-test.
#
# Usage: scripts/check_web_build_selftest.sh      (exit 0 = every case behaves)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK="$ROOT/scripts/check_web_build.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

fixture() {  # name -> a minimal publishable build under $TMP/name
    local d="$TMP/$1"
    mkdir -p "$d/assets/assets/rules"
    for f in index.html main.dart.js sqlite3.wasm drift_worker.js; do
        printf 'x' > "$d/$f"
    done
    printf '# rules' > "$d/assets/assets/rules/zapzap.fr.md"
    echo "$d"
}

expect() {  # description, expected exit code, build dir
    "$CHECK" "$3" > /dev/null 2>&1
    local got=$?
    if [ "$got" -eq "$2" ]; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        printf '  FAIL  %s\n        expected exit %s, got %s\n' "$1" "$2" "$got"
    fi
}

d=$(fixture ok)
expect "a clean build, shipped rules included" 0 "$d"
expect "the same build, given with a trailing slash" 0 "$d/"

d=$(fixture leak_root)
printf 'notes' > "$d/CLAUDE.md"
expect "a Markdown file at the root" 1 "$d"

d=$(fixture leak_upper)
printf 'notes' > "$d/NOTES.MD"
expect "an upper-case .MD" 1 "$d"

d=$(fixture leak_nested)
mkdir -p "$d/icons"
printf 'notes' > "$d/icons/README.md"
expect "a Markdown file in a subdirectory" 1 "$d"

d=$(fixture leak_assets)
printf 'notes' > "$d/assets/README.md"
expect "a Markdown file in assets/ but outside assets/assets/" 1 "$d"

for f in index.html main.dart.js sqlite3.wasm drift_worker.js; do
    d=$(fixture "missing_$f")
    rm "$d/$f"
    expect "a missing $f" 1 "$d"
    d=$(fixture "empty_$f")
    : > "$d/$f"
    expect "an empty $f" 1 "$d"
done

expect "no build at all" 1 "$TMP/does-not-exist"

"$CHECK" a b > /dev/null 2>&1
if [ $? -eq 2 ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "  FAIL  two arguments is not a usage error"; fi

# Both publishing paths must call the check, or the two drift apart again.
for caller in scripts/deploy_web.sh .github/workflows/deploy-pages.yml; do
    if grep -q 'scripts/check_web_build.sh' "$ROOT/$caller"; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "  FAIL  $caller no longer runs scripts/check_web_build.sh"
    fi
done

# The Pages workflow must also refuse a stale web/ binary, as the `app` CI job does.
if grep -q 'scripts/web_binaries.sh --check' "$ROOT/.github/workflows/deploy-pages.yml"; then
    pass=$((pass + 1))
else
    fail=$((fail + 1))
    echo "  FAIL  deploy-pages.yml no longer runs scripts/web_binaries.sh --check"
fi

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
