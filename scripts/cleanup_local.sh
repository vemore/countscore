#!/bin/bash

# CountScore - remove the local worktrees and branches that no longer serve anything.
#
# Parallel work leaves debris: a worktree per pull request, the `worktree-<name>`
# branch the Agent tool creates before the agent switches to its real branch, a
# deploy worktree, and a local branch per merged pull request. Pull requests are
# squash-merged, so `git branch -d` never recognises them as merged, and `-D` would
# happily destroy a commit that never reached GitHub. This decides on evidence.
#
# A local branch is deleted when either:
#   - it has no commit of its own (nothing ahead of origin/main), or
#   - GitHub reports a MERGED pull request for it, and its local tip is contained
#     in that pull request's head (GitHub compare: identical or behind) -- so every
#     local commit was part of what merged.
# Anything else is kept, with the reason: no pull request, pull request open or
# closed, local commits beyond the merged head, or GitHub unreachable.
#
# A worktree (never the main checkout) is removed when it has no uncommitted or
# untracked change, and its branch is deletable -- or it is detached on a commit
# already in origin/main.
#
# Never run it while agents are still working: a freshly created branch with no
# commit yet, in a clean worktree, is indistinguishable from an abandoned one.
#
# Usage: scripts/cleanup_local.sh            dry run: print what would go, and why
#        scripts/cleanup_local.sh --apply    do it

set -uo pipefail

apply=0
case "${1:-}" in
    --apply) apply=1 ;;
    "") ;;
    -h|--help) sed -n '3,28p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
esac

MAIN="$(cd "$(git rev-parse --git-common-dir)/.." && pwd)"
cd "$MAIN" || exit 1
git fetch --prune -q origin 2>/dev/null || echo "warning: fetch failed, origin/main may be stale" >&2
git rev-parse --verify -q origin/main >/dev/null || { echo "no origin/main" >&2; exit 1; }

gh_ok=0
command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 && gh_ok=1

REASON=""
deletable() {  # branch -> 0 if it may go; REASON says why, either way
    local branch="$1" ahead head status
    ahead=$(git rev-list --count "origin/main..$branch" 2>/dev/null || echo 1)
    if [ "$ahead" -eq 0 ]; then
        REASON="no commit of its own"
        return 0
    fi
    if [ "$gh_ok" = 0 ]; then
        REASON="$ahead commit(s) ahead, and gh is unavailable to prove they merged"
        return 1
    fi
    head=$(timeout 20 gh pr list --head "$branch" --state merged --limit 1 \
           --json headRefOid,number --jq '.[0] | "\(.headRefOid) \(.number)"' 2>/dev/null)
    if [ -z "$head" ] || [ "$head" = "null null" ]; then
        local open
        open=$(timeout 20 gh pr list --head "$branch" --state all --limit 1 \
               --json number,state --jq '.[0] | "#\(.number) \(.state)"' 2>/dev/null)
        REASON="$ahead commit(s) ahead, pull request: ${open:-none}"
        return 1
    fi
    status=$(timeout 20 gh api "repos/{owner}/{repo}/compare/${head%% *}...$(git rev-parse "$branch")" \
             --jq .status 2>/dev/null)
    case "$status" in
        identical|behind)
            REASON="pull request #${head##* } merged, local tip included"
            return 0 ;;
        "")
            REASON="pull request #${head##* } merged, but the local tip is not on GitHub"
            return 1 ;;
        *)
            REASON="pull request #${head##* } merged, but the local tip has commits beyond it ($status)"
            return 1 ;;
    esac
}

act() {  # description, command...
    local what="$1"; shift
    if [ "$apply" = 1 ]; then
        "$@" >/dev/null 2>&1 && echo "  removed  $what" || echo "  FAILED   $what"
    else
        echo "  would remove  $what"
    fi
}

removed_worktrees=()
declare -A kept_branch=()
kept_branch[main]=1
current=$(git rev-parse --abbrev-ref HEAD)
kept_branch[$current]=1

echo "Worktrees"
while IFS=$'\t' read -r path ref; do
    [ "$path" = "$MAIN" ] && continue
    if [ ! -d "$path" ]; then
        continue  # pruned below
    fi
    if [ -n "$(git -C "$path" status --porcelain 2>/dev/null)" ]; then
        echo "  keep     $path — uncommitted or untracked changes"
        [ -n "$ref" ] && kept_branch[$ref]=1
        continue
    fi
    if [ -z "$ref" ]; then
        if git merge-base --is-ancestor "$(git -C "$path" rev-parse HEAD)" origin/main 2>/dev/null; then
            act "$path (detached, on main)" git worktree remove "$path"
            removed_worktrees+=("$path")
        else
            echo "  keep     $path — detached on a commit not in origin/main"
        fi
        continue
    fi
    if deletable "$ref"; then
        act "$path ($ref: $REASON)" git worktree remove "$path"
        removed_worktrees+=("$path")
    else
        echo "  keep     $path ($ref) — $REASON"
        kept_branch[$ref]=1
    fi
done < <(git worktree list --porcelain | awk '
    /^worktree / { if (p != "") print p "\t" b; p = substr($0, 10); b = "" }
    /^branch /   { b = substr($0, 19) }
    END          { if (p != "") print p "\t" b }')
[ "$apply" = 1 ] && git worktree prune

echo "Branches"
while read -r branch; do
    if [ -n "${kept_branch[$branch]:-}" ]; then
        [ "$branch" = "$current" ] && [ "$branch" != main ] && deletable "$branch" \
            && echo "  keep     $branch — checked out in the main checkout ($REASON): switch to main first"
        continue
    fi
    if deletable "$branch"; then
        act "$branch — $REASON" git branch -D "$branch"
    else
        echo "  keep     $branch — $REASON"
    fi
done < <(git for-each-ref --format='%(refname:short)' refs/heads)

[ "$apply" = 0 ] && echo && echo "Dry run. Re-run with --apply to remove the lines marked 'would remove'."
exit 0
