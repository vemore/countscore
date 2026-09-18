#!/bin/bash

# CountScore - CI scope classifier self-test
#
# scripts/ci_scope.sh decides which CI jobs a pull request does *not* run, so a
# wrong rule does not turn a build red -- it merges something nothing tested.
# The interesting cases are the paths that look like documentation and are not
# (.claude/hooks/guard-bash.sh, .github/workflows/ci.yml), the ones that look
# like code and are not (backend/README.md), and the ones nobody has classified
# yet. This table runs as the first step of the `scope` job, in about a second.
#
# Usage: scripts/ci_scope_selftest.sh      (exit 0 = every case classifies)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCOPE="$ROOT/scripts/ci_scope.sh"
WORKFLOW="$ROOT/.github/workflows/ci.yml"

pass=0
fail=0

report() {  # description, expected, actual
    if [ "$2" = "$3" ]; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        printf '  FAIL  %s\n        expected [%s], got [%s]\n' "$1" "$2" "$3"
    fi
}

jobs_for() {  # paths on stdin -> the jobs that run, space separated, workflow order
    "$SCOPE" | sed -n 's/=true$//p' | tr '\n' ' '
}

scope() {  # description, expected jobs, paths...
    local desc="$1" expected="$2" actual
    shift 2
    actual=$(printf '%s\n' "$@" | jobs_for)
    report "$desc" "$expected" "${actual% }"
}

echo "== nothing to run ============================================"
scope "a documentation-only change"     ""  README.md .llmwiki/Testing.md
scope "a README inside the backend"     ""  backend/README.md
scope "the backend's own CLAUDE.md"     ""  backend/CLAUDE.md
scope "a wip entry"                     ""  wip/todo_nr/2026-09-16-x.md
scope "a skill's prose"                 ""  .claude/skills/ship-parallel/SKILL.md
scope "a scoped rule"                   ""  .claude/rules/web.md
scope "the store listing and a graphic" ""  store_listing/en-US/title.txt \
                                            store_listing/assets/feature_graphic.png
scope "the rendered privacy page"       ""  docs/privacy-policy.html
scope "the licence"                     ""  LICENSE
report "no changed file at all"         ""  "$(jobs_for < /dev/null)"

echo "== one area =================================================="
scope "the server"           "backend image sync"  backend/app/routers/sync.py
scope "the backend lock"     "backend image sync"  backend/uv.lock
scope "a migration"          "backend image sync"  backend/alembic/versions/0002_x.py
scope "a backend test"       "backend image sync"  backend/tests/test_sync.py
scope "the backup sidecar"   "backend image sync"  backend/Dockerfile.backup
scope "the backup script"    "backend image sync"  backend/backup/countscore-backup.sh
scope "the prod compose"     "backend image sync"  backend/docker-compose.prod.yml
scope "the Gradle project"   "android"             android/app/build.gradle.kts
scope "the manifest"         "android"             android/app/src/main/AndroidManifest.xml
scope "the web shell"        "app"                 web/index.html
scope "the drift worker"     "app"                 web/drift_worker.js
scope "Dart"                 "app android sync"    lib/services/drift/database.dart
scope "an ARB file"          "app android sync"    lib/l10n/app_fr.arb
scope "the l10n config"      "app android sync"    l10n.yaml
scope "a Dart test"          "app android sync"    test/drift/drift_repositories_test.dart
scope "the e2e suite"        "app android sync"    integration_test/app_test.dart
scope "a Flutter dependency" "app android sync"    pubspec.yaml pubspec.lock
scope "the pub lock alone"    "app android sync"    pubspec.lock
scope "the analysis options" "app android sync"    analysis_options.yaml

echo "== everything ================================================"
all="backend image app android sync"
scope "the workflow itself"    "$all"  .github/workflows/ci.yml
scope "dependabot"             "$all"  .github/dependabot.yml
scope "the OSV ignore list"     "$all"  .github/osv-scanner.toml
scope "a Claude Code hook"     "$all"  .claude/hooks/guard-bash.sh
scope "the hook settings"      "$all"  .claude/settings.json
scope "the release tooling"    "$all"  .claude/skills/release-android/scripts/play_publish.py
scope "a script"               "$all"  scripts/cleanup_local.sh
scope "the classifier itself"  "$all"  scripts/ci_scope.sh
scope "iOS"                    "$all"  ios/Runner/Info.plist
scope "an unknown new path"    "$all"  platform/windows/runner/main.cpp
scope "an unknown root config" "$all"  renovate.json

echo "== mixed ====================================================="
scope "documentation plus the server"   "backend image sync"  README.md backend/app/main.py
scope "the server and Dart"             "$all"                backend/app/main.py lib/main.dart
scope "a rename out of lib/ into docs"  "app android sync"    lib/old.dart docs/old.md
scope "documentation plus the workflow" "$all"                README.md .github/workflows/ci.yml
scope "the Android manifest and Dart"   "app android sync"    android/app/src/main/AndroidManifest.xml \
                                                              lib/main.dart

echo "== the contract with ci.yml =================================="
flat=$("$SCOPE" < /dev/null | tr '\n' ' ')
report "five flags, in workflow order, all false" \
    "backend=false image=false app=false android=false sync=false" "${flat% }"

# A renamed flag, or an `if:` hand-edited back to the weaker `== 'true'`, would
# leave the classifier correct and the workflow deaf to it. Nothing else notices.
for job in backend image app android sync; do
    if grep -q "needs.scope.outputs.$job != 'false'" "$WORKFLOW"; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "  FAIL  ci.yml does not gate the $job job on scope's $job flag"
    fi
done

# The pulls/{n}/files endpoint has no `path` key: `-q '.[].path'` yields one null
# per file, every null hits the catch-all, and the whole change silently no-ops.
if grep -q '\.filename' "$WORKFLOW"; then
    pass=$((pass + 1))
else
    fail=$((fail + 1))
    echo "  FAIL  ci.yml does not read .filename from the pull request files endpoint"
fi

if grep -q 'previous_filename' "$WORKFLOW"; then
    pass=$((pass + 1))
else
    fail=$((fail + 1))
    echo "  FAIL  ci.yml does not feed renames through previous_filename"
fi

# A workflow-level paths: filter would leave a required check reporting nothing
# at all, and a documentation-only pull request waiting forever.
if grep -Eq '^\s*(paths|paths-ignore):' "$WORKFLOW"; then
    fail=$((fail + 1))
    echo "  FAIL  ci.yml has a workflow-level paths: filter — a filtered required check never reports"
else
    pass=$((pass + 1))
fi

# The rules above route pubspec.lock to `app` and backend/Dockerfile.backup to
# `image` because those jobs gate them; a routing with nothing behind it is a lie.
if grep -q 'lockfile pubspec.lock' "$WORKFLOW"; then
    pass=$((pass + 1))
else
    fail=$((fail + 1))
    echo "  FAIL  ci.yml no longer audits pubspec.lock with osv-scanner"
fi

if grep -q 'Dockerfile.backup' "$WORKFLOW"; then
    pass=$((pass + 1))
else
    fail=$((fail + 1))
    echo "  FAIL  ci.yml no longer builds backend/Dockerfile.backup"
fi

if [ -x "$SCOPE" ]; then
    pass=$((pass + 1))
else
    fail=$((fail + 1))
    echo "  FAIL  $SCOPE is not executable"
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
