#!/bin/bash

# CountScore - self-test for scripts/retry_sqlite3_hash.sh and the sqlite3
# native-asset cache in .github/workflows/ci.yml.
#
# The retry must never turn a real failure green: it retries only on the hook's
# hash message, only once, and the second attempt's status is final. Runs in the
# `scope` job, next to the scope classifier's table, in well under a second.
#
# Usage: scripts/retry_sqlite3_hash_selftest.sh      (exit 0 = every case holds)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RETRY="$ROOT/scripts/retry_sqlite3_hash.sh"
WORKFLOW="$ROOT/.github/workflows/ci.yml"

pass=0
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

report() {  # description, expected, actual
    if [ "$2" = "$3" ]; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        printf '  FAIL  %s\n        expected [%s], got [%s]\n' "$1" "$2" "$3"
    fi
}

HASH='Bad state: Hash of downloaded file libsqlite3.x64.linux.so is 2514114, expected 4b986901.'

# A fake command: attempt N prints the Nth message and exits with the Nth status.
# Its arguments are "msg1|status1" "msg2|status2" ...; it counts its runs.
fake="$tmp/fake.sh"
cat > "$fake" <<'EOF'
#!/bin/bash
n=$(( $(cat "$COUNTER" 2>/dev/null || echo 0) + 1 ))
echo "$n" > "$COUNTER"
spec="${!n:-|0}"
[ -z "${spec%|*}" ] || echo "${spec%|*}" >&2
exit "${spec##*|}"
EOF
chmod +x "$fake"

case_() {  # description, expected "status runs", attempt specs...
    local desc="$1" expected="$2" status runs
    shift 2
    export COUNTER="$tmp/counter"
    rm -f "$COUNTER"
    "$RETRY" "$fake" "$@" > /dev/null 2>&1
    status=$?
    runs=$(cat "$COUNTER" 2>/dev/null || echo 0)
    report "$desc" "$expected" "$status $runs"
}

echo "== retry_sqlite3_hash.sh ====================================="
case_ "a success runs once"                         "0 1"  "|0"
case_ "an unrelated failure is not retried"         "1 1"  "Some test failed|1"
case_ "its exit status is kept"                     "7 1"  "Gradle said no|7"
case_ "the hash message, then a pass: green"        "0 2"  "$HASH|1" "|0"
case_ "the hash message twice: red"                 "1 2"  "$HASH|1" "$HASH|1"
case_ "the hash message, then another failure: red" "3 2"  "$HASH|1" "Some test failed|3"
case_ "never a third attempt"                       "1 2"  "$HASH|1" "$HASH|1" "|0"
case_ "the message on a zero exit is not a failure" "0 1"  "$HASH|0"

"$RETRY" > /dev/null 2>&1
report "no command is a usage error" "2" "$?"

echo "== the contract with ci.yml =================================="
# Every job whose Flutter build runs the sqlite3 hook restores the native
# libraries it downloaded, keyed on the sqlite3 version pubspec.lock resolves,
# and wraps the step that runs the hook in the retry.
for job in app sync android; do
    block=$(awk -v j="  $job:" '$0 == j {on=1; next} on && /^  [a-z_]+:$/ {on=0} on' "$WORKFLOW")
    if grep -q 'hooks_runner/shared/sqlite3/build/download-\*' <<< "$block" \
        && grep -q 'steps.sqlite3.outputs.version' <<< "$block"; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "  FAIL  the $job job does not cache the sqlite3 native libraries by version"
    fi
    if grep -q 'scripts/retry_sqlite3_hash.sh flutter' <<< "$block"; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "  FAIL  the $job job does not retry its sqlite3 build hook on a bad download"
    fi
done

# The version read by the workflow must be the one pubspec.lock pins.
lock_version=$(awk '/^  sqlite3:$/ {on=1} on && /^    version:/ {gsub(/"/, "", $2); print $2; exit}' "$ROOT/pubspec.lock")
if [ -n "$lock_version" ]; then
    pass=$((pass + 1))
else
    fail=$((fail + 1))
    echo "  FAIL  no sqlite3 version found in pubspec.lock — the cache key would be empty"
fi

for f in "$RETRY" "$0"; do
    if [ -x "$f" ]; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "  FAIL  $f is not executable"
    fi
done

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
