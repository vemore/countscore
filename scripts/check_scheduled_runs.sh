#!/bin/bash

# CountScore - is the scheduled half of CI still running?
#
# GitHub disables a scheduled workflow after 60 days with no *repository activity*, and
# re-enabling it is a manual click. Two workflows here are triggered by `schedule:` and by
# nothing else, so when that happens they simply stop, and nothing goes red: a scheduled
# run has no pull request in front of it, so no hook and no required check answers for it.
#
#   ci.yml   weekly  - its `backend` job carries `pip-audit`, the only dependency scan that
#                      *fails a build* in this project. Since the `scope` job it no longer
#                      runs on a pull request that leaves backend/ alone, so this weekly run
#                      is what caps the exposure window.
#   deps.yml monthly - the transitive refresh of pubspec.lock and the committed web/ binaries.
#
# The moment that matters is the repository coming back to life after a quiet spell: the
# cron is off, and nothing says so. That is why this is wired into the SessionStart hook
# (.claude/hooks/session-start.sh), rate-limited to once a day.
#
# Usage: scripts/check_scheduled_runs.sh
#   exit 0  every watched workflow is enabled and has run recently enough  (silent)
#   exit 1  one is disabled, or its newest scheduled run is too old        (report on stdout)
#   exit 3  could not check: no `gh`, not authenticated, origin is not GitHub, no network
#           (silent -- never block or slow down a session over this)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" 2>/dev/null || exit 3

# file | cadence | how old its newest scheduled run may get, in days | why it matters
#
# The threshold is per workflow on purpose: a single 10-day window would cry wolf at
# deps.yml every single month. Each is its own period plus slack -- GitHub delays a
# scheduled run under load and never makes it up.
WATCHED="\
ci.yml|weekly|10|it carries pip-audit, the only dependency scan that fails a build here
deps.yml|monthly|40|it is what keeps pubspec.lock and the committed web/ binaries current"

case "$(git remote get-url origin 2>/dev/null)" in *github.com*) ;; *) exit 3 ;; esac
command -v gh >/dev/null 2>&1 || exit 3
gh auth status >/dev/null 2>&1 || exit 3

# One call for every workflow's state. `disabled_inactivity` is GitHub's own name for the
# 60-day rule, so it is the direct evidence; the run age below is the second signal, and
# catches a workflow that is nominally active but not firing.
states=$(timeout 20 gh api "repos/{owner}/{repo}/actions/workflows" \
    --jq '.workflows[] | "\(.path)\t\(.state)"' 2>/dev/null)
[ -z "$states" ] && exit 3

now=$(date -u +%s 2>/dev/null) || exit 3
found=0

while IFS='|' read -r file cadence max_days why; do
    [ -z "$file" ] && continue

    state=$(printf '%s\n' "$states" |
        awk -F'\t' -v p=".github/workflows/$file" '$1 == p { print $2 }')
    # Not on the default branch yet -- a workflow added on this branch is not overdue.
    [ -z "$state" ] && continue

    if [ "$state" != "active" ]; then
        found=1
        echo "Workflow $file is not active on GitHub: state \"$state\"."
        echo "  A scheduled workflow is disabled after 60 days without repository activity,"
        echo "  and re-enabling it is manual. It is not decoration: $why."
        echo "  gh workflow enable $file && gh workflow run $file"
        continue
    fi

    newest=$(timeout 20 gh run list --workflow="$file" --event schedule --limit 1 \
        --json createdAt --jq '.[0].createdAt' 2>/dev/null)
    [ "$newest" = "null" ] && newest=""

    if [ -n "$newest" ]; then
        since="its newest scheduled run was on ${newest%%T*}"
    else
        # No scheduled run on record: either the cron is new, or the runs have aged out of
        # GitHub's 90-day retention. Both are measured from the commit that last touched a
        # `cron:` line -- the day the schedule as it stands began to mean something. A
        # workflow whose cron landed last week is not overdue; editing an unrelated job in
        # the same file does not reset the clock.
        newest=$(git log -1 --format=%cI -S'cron:' origin/main -- ".github/workflows/$file" 2>/dev/null)
        [ -z "$newest" ] && newest=$(git log -1 --format=%cI -S'cron:' HEAD -- ".github/workflows/$file" 2>/dev/null)
        [ -z "$newest" ] && continue
        since="it has no scheduled run on record, and its cron landed on ${newest%%T*}"
    fi

    then_s=$(date -u -d "$newest" +%s 2>/dev/null) || continue
    age=$(( (now - then_s) / 86400 ))
    [ "$age" -le "$max_days" ] && continue

    found=1
    echo "Workflow $file is $cadence; $since -- $age days ago."
    echo "  GitHub disables a scheduled workflow after 60 days without repository activity,"
    echo "  and nothing goes red when it stops: $why."
    echo "  gh run list --workflow=$file --event schedule --limit 5"
    echo "  gh workflow enable $file && gh workflow run $file"
done <<< "$WATCHED"

[ "$found" -eq 0 ]
