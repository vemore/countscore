#!/bin/bash

# CountScore - session opener (Claude Code SessionStart hook)
#
# SessionStart is one of the few events whose plain stdout is injected into the
# conversation, so this says the two things that are only actionable BEFORE work
# starts: whether the clone still needs code generation, and whether the branch
# left over from the previous session is safe to commit on.

set -uo pipefail

payload=$(cat 2>/dev/null)
cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)
ROOT=""
[ -n "$cwd" ] && ROOT=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
[ -z "$ROOT" ] && ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$ROOT" 2>/dev/null || exit 0

if [ -z "$(find lib -name '*.g.dart' -print -quit 2>/dev/null)" ]; then
    echo "Generated code is missing: run \`dart run build_runner build\` before anything else"
    echo "(no --delete-conflicting-outputs -- build_runner 2.16 removed the flag). Nothing compiles until then."
fi

# A merged pull request whose base was not `main` merged into that base. If the base
# was itself merged first, the child's work never reached main -- it happened on
# 2026-09-09 and was invisible until someone looked at `git ls-tree origin/main`.
delivery_check() {
    case "$(git remote get-url origin 2>/dev/null)" in *github.com*) ;; *) return ;; esac
    command -v gh >/dev/null 2>&1 || return
    gh auth status >/dev/null 2>&1 || return

    local cutoff acked
    cutoff=$(date -u -d '14 days ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || return
    acked=" $(git config --get-all countscore.deliveryAcknowledged 2>/dev/null | tr '\n' ' ') "

    timeout 20 gh pr list --state merged --limit 30 \
        --json number,title,baseRefName,mergeCommit,mergedAt \
        --jq ".[] | select(.baseRefName != \"main\") | select(.mergedAt > \"$cutoff\") | \"\(.number)\t\(.baseRefName)\t\(.mergeCommit.oid)\t\(.title)\"" \
        2>/dev/null |
    while IFS=$'\t' read -r number base sha title; do
        case "$acked" in *" $number "*) continue ;; esac
        # Ask GitHub rather than git: the merge commit of a deleted branch may not
        # exist in this clone at all.
        case "$(timeout 20 gh api "repos/{owner}/{repo}/compare/main...$sha" --jq .status 2>/dev/null)" in
            identical|behind) continue ;;
        esac
        echo "PR #$number merged into '$base', not into main, and its commits are not on main:"
        echo "  \"$title\" — check whether that work reached main another way. If it did,"
        echo "  record it: git config --add countscore.deliveryAcknowledged $number"
    done
}

# Parallel work lives in worktrees, one per pull request. A session that resumes the
# orchestration needs to see them before it starts anything new.
worktrees_report() {
    local lines
    lines=$(git worktree list --porcelain 2>/dev/null | awk -v root="$ROOT" '
        /^worktree / { if (p != "" && p != root) print p "\t" b; p = substr($0, 10); b = "(detached)" }
        /^branch /   { b = substr($0, 19) }
        END          { if (p != "" && p != root) print p "\t" b }')
    local gone
    gone=$(git for-each-ref --format='%(upstream:track)' refs/heads 2>/dev/null | grep -c '^\[gone\]$')
    [ -z "$lines" ] && [ "${gone:-0}" -eq 0 ] && return
    if [ -n "$lines" ]; then
        echo "Other worktrees of this repository:"
        printf '%s\n' "$lines" | while IFS=$'\t' read -r path branch; do
            echo "  $branch  ->  $path"
        done
    fi
    [ "${gone:-0}" -gt 0 ] && echo "$gone local branch(es) whose remote branch was deleted."
    echo "Once no agent is working in them: scripts/cleanup_local.sh (dry run), then --apply."
}

git rev-parse --git-dir >/dev/null 2>&1 || exit 0
worktrees_report
delivery_check
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
[ -z "$branch" ] && exit 0

if git rev-parse --verify -q origin/main >/dev/null 2>&1; then
    counts=$(git rev-list --left-right --count origin/main...HEAD 2>/dev/null)
    behind=$(echo "$counts" | cut -f1)
    ahead=$(echo "$counts" | cut -f2)
    track=$(git for-each-ref --format='%(upstream:track)' "refs/heads/$branch" 2>/dev/null)
    stale=""
    [ "$track" = "[gone]" ] && stale="its remote branch was merged and deleted"
    if [ -z "$stale" ] && [ "${ahead:-0}" -gt 0 ] && [ "${ahead:-0}" -le 50 ]; then
        git cherry origin/main HEAD 2>/dev/null | grep -q '^-' \
            && stale="it replays commits already on origin/main"
    fi
    echo "Branch: $branch (${ahead:-0} ahead, ${behind:-0} behind origin/main)"
    if [ "$branch" = "main" ] || [ -n "$stale" ]; then
        [ -n "$stale" ] && echo "This branch is not safe to commit on -- $stale."
        echo "Start the work in its own worktree, on a fresh branch (the main checkout stays on main):"
        echo "  git fetch --prune origin && git worktree add ../countscore-<topic> -b <type>/<topic> origin/main"
    fi
fi
exit 0
