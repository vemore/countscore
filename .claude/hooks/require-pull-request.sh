#!/bin/bash

# CountScore - pull-request reminder (Claude Code Stop hook)
#
# A change that only exists as a local commit is not delivered. This asks, when a
# turn ends, whether the commits on this branch have a pull request yet, and
# whether that pull request is green -- the two halves of "finished".
#
# It is deliberately quiet: it says nothing on main, on a branch with nothing to
# publish, or while the checks are still running. It never pushes and never opens
# anything itself; opening a pull request is an outward-facing act and stays a
# deliberate one.
#
# Escape hatch, for a branch that is genuinely not meant to be published yet:
#   git config branch.<branch>.noPullRequest true

set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$ROOT" 2>/dev/null || exit 0

payload=$(cat)
# Already asked once and Claude is still working on it: do not ask again, or the
# turn never ends.
[ "$(printf '%s' "$payload" | jq -r '.stop_hook_active // false' 2>/dev/null)" = "true" ] && exit 0

git rev-parse --git-dir >/dev/null 2>&1 || exit 0
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
[ -z "$branch" ] || [ "$branch" = "HEAD" ] || [ "$branch" = "main" ] && exit 0
[ "$(git config --get --bool "branch.$branch.noPullRequest" 2>/dev/null)" = "true" ] && exit 0

git rev-parse --verify -q origin/main >/dev/null 2>&1 || exit 0
[ "$(git rev-list --count origin/main..HEAD 2>/dev/null || echo 0)" -gt 0 ] || exit 0

case "$(git remote get-url origin 2>/dev/null)" in
    *github.com*) ;;
    *) exit 0 ;;   # nothing to open a pull request against
esac
command -v gh >/dev/null 2>&1 || exit 0
gh auth status >/dev/null 2>&1 || exit 0

block() {
    jq -n --arg r "$1" '{decision:"block", reason:$r}'
    exit 0
}

# `.[0] | ...` on an empty result yields the string "null null", not nothing.
pr=$(timeout 20 gh pr list --head "$branch" --state open --json number,url \
     --jq '.[] | "\(.number) \(.url)"' 2>/dev/null | head -1)

if [ -z "$pr" ]; then
    dirty=""
    git diff --quiet 2>/dev/null || dirty="Commit the remaining changes first, then open it. "
    block "This branch has $(git rev-list --count origin/main..HEAD) commit(s) that no pull request covers.

A change that lives only in a local commit is not delivered: it is not reviewed, CI has
never run on it, and nobody else can see it. ${dirty}Push the branch and open the pull
request now, with a body that says what changed and why -- then report its URL and the
state of its checks.

  git push -u origin $branch
  gh pr create --base <the branch this stacks on, usually main> --head $branch --title ... --body ...

If this branch is genuinely not meant to be published yet, say so to the user and set
\`git config branch.$branch.noPullRequest true\`."
fi

number=${pr%% *}
url=${pr#* }
failing=$(timeout 30 gh pr checks "$number" --required 2>/dev/null | awk -F'\t' '$2 == "fail" {print "  " $1 "  " $4}')
[ -z "$failing" ] && failing=$(timeout 30 gh pr checks "$number" 2>/dev/null | awk -F'\t' '$2 == "fail" {print "  " $1 "  " $4}')

if [ -n "$failing" ]; then
    block "Pull request $url has failing checks:

$failing

The change is not finished while its own CI is red -- open the failing job, fix what it
found, and push. If the failure is unrelated to this branch, say so to the user rather
than leaving it unexplained."
fi
exit 0
