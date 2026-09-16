#!/bin/bash

# CountScore - make a git worktree ready to build, test and deploy.
#
# A worktree is a fresh checkout: no *.g.dart (gitignored), no .dart_tool, no
# backend virtualenv, and none of the untracked local files that only the main
# checkout holds. Without this, `flutter analyze` fails on missing generated code
# and the commit hook refuses every commit for a reason unrelated to the change.
#
# Usage: scripts/worktree_setup.sh [worktree dir]   (default: the current repository)
#        --no-app      skip the Flutter steps (backend-only work)
#        --no-backend  skip `uv sync`
#
# Local-only files are linked, never copied, so a rotated password is seen everywhere
# and nothing is duplicated on disk. All of them are gitignored, and the commit hook
# refuses a staged keystore, key.properties or .env anyway.
#
# While it runs, the worktree carries a `.countscore-setup-in-progress` marker (pid, date,
# branch) and `scripts/cleanup_local.sh` refuses to remove a worktree that has one — codegen
# writes only gitignored files, so a half-built worktree reads as perfectly clean. A failed
# setup leaves the marker on purpose: that worktree is exactly the one not to delete. Rerun
# this script, or `rm <worktree>/.countscore-setup-in-progress` once you have judged it stale.

set -euo pipefail

app=1
backend=1
dir=""
for arg in "$@"; do
    case "$arg" in
        --no-app) app=0 ;;
        --no-backend) backend=0 ;;
        -h|--help) sed -n '3,23p' "$0"; exit 0 ;;
        *) dir="$arg" ;;
    esac
done

TREE="$(git -C "${dir:-.}" rev-parse --show-toplevel)"
# The main checkout is the worktree that owns the shared .git directory.
MAIN="$(cd "$(git -C "$TREE" rev-parse --git-common-dir)/.." && pwd)"
cd "$TREE"

# Claim the worktree before anything slow starts. No `trap` clears it: under `set -e` a
# failed setup must leave the marker, so cleanup_local.sh keeps the half-built worktree.
MARKER="$TREE/.countscore-setup-in-progress"
echo "pid $$ started $(date -Iseconds) branch $(git rev-parse --abbrev-ref HEAD)" > "$MARKER"

echo "worktree: $TREE"
echo "main checkout: $MAIN"

LOCAL_ONLY=(
    backend/scripts/deploy.env   # deployment target (backend-deploy, web-deploy)
    android/key.properties       # upload keystore passwords (release-android)
)
if [ "$TREE" != "$MAIN" ]; then
    for file in "${LOCAL_ONLY[@]}"; do
        if [ -e "$MAIN/$file" ] && [ ! -e "$TREE/$file" ]; then
            ln -s "$MAIN/$file" "$TREE/$file"
            echo "linked $file"
        fi
    done
fi

if [ "$app" = 1 ]; then
    flutter pub get
    dart run build_runner build
    flutter gen-l10n
fi

if [ "$backend" = 1 ] && command -v uv >/dev/null 2>&1; then
    (cd backend && uv sync --locked --extra dev)
fi

rm -f "$MARKER"
echo "ready: $TREE ($(git rev-parse --abbrev-ref HEAD))"
