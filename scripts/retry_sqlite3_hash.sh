#!/bin/bash

# CountScore - run a CI command, and run it once more only if package:sqlite3's
# build hook rejected a download.
#
# The hook (sqlite3 3.x, lib/src/hook/compile/description.dart) fetches a
# precompiled libsqlite3 from the package's GitHub release and hashes the body
# without looking at the HTTP status, so an error page from GitHub fails as
# `Bad state: Hash of downloaded file <name> is <digest>, expected <hash>.` Runs
# 35335702639 (Android) and 35429735515 (Sync) both saw digest 2514114...f003 --
# the same wrong body for two different files -- and passed when rerun.
#
# The native-asset cache in .github/workflows/ci.yml is the fix; this covers the
# first download after a sqlite3 bump, when every job misses that cache. The hash
# check itself is untouched: the second attempt downloads and verifies again, and
# its exit status is final, so a job that fails twice with the message fails. Any
# other failure is returned at once, never retried.
#
# Usage: scripts/retry_sqlite3_hash.sh <command> [args...]
# Pinned by scripts/retry_sqlite3_hash_selftest.sh.

set -uo pipefail

[ "$#" -gt 0 ] || { echo "usage: $0 <command> [args...]" >&2; exit 2; }

MESSAGE='Hash of downloaded file'

log=$(mktemp)
trap 'rm -f "$log"' EXIT

"$@" 2>&1 | tee "$log"
status=${PIPESTATUS[0]}

[ "$status" -ne 0 ] || exit 0
grep -q "$MESSAGE" "$log" || exit "$status"

echo "::warning::package:sqlite3 rejected a downloaded native library (exit $status) — retrying once; the hash is checked again"
"$@"
