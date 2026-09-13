#!/bin/bash
# Build the CountScore PWA and publish it to the NAS, where the backend container
# serves it under PWA_BASE_PATH on the backend's own host — no Web Station change.
#
# The target is the backend's: NAS_SSH, NAS_DEPLOY_DIR and PUBLIC_URL come from the
# untracked backend/scripts/deploy.env (template: deploy.env.example), because this
# repository is public. The build lands in $NAS_DEPLOY_DIR/pwa/current, which
# docker-compose.prod.yml bind-mounts read-only into the api container.
#
# The sub-path is NOT configured here: it is read from PWA_BASE_PATH in the NAS .env,
# the same value the backend mounts the PWA at, so the build's --base-href cannot
# disagree with it. Export PWA_BASE_PATH to override (e.g. for --dry-run offline).
#
# Prereqs (one-time, see the web-deploy skill):
#   - PWA_BASE_PATH set in $NAS_DEPLOY_DIR/.env, e.g. PWA_BASE_PATH=/countscore
#   - the backend deployed with a docker-compose.prod.yml that has the pwa volume
#
# Usage:
#   scripts/deploy_web.sh               # build + check + publish current tree
#   scripts/deploy_web.sh --dry-run     # build + check, print the remote commands
#   scripts/deploy_web.sh --rollback    # swap the previous release back in
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/backend/scripts/deploy.env"
# shellcheck source=/dev/null
[[ -f "$CONFIG" ]] && source "$CONFIG"

MODE="${1:-deploy}"
case "$MODE" in
    deploy | --dry-run | --rollback) ;;
    *)
        echo "Usage: deploy_web.sh [--dry-run | --rollback]" >&2
        exit 2
        ;;
esac

# Fail loudly and by name rather than deploying somewhere unintended.
: "${NAS_SSH:?set NAS_SSH in backend/scripts/deploy.env (see deploy.env.example)}"
: "${NAS_DEPLOY_DIR:?set NAS_DEPLOY_DIR in backend/scripts/deploy.env (see deploy.env.example)}"
PUBLIC_URL="${PUBLIC_URL:-<your public URL>}"

# The folder is interpolated into a remote shell and has rm -rf run on its
# .new/.prev siblings: accept only a plain absolute path.
if [[ ! "$NAS_DEPLOY_DIR" =~ ^(/[A-Za-z0-9_-][A-Za-z0-9._-]*)+$ ]]; then
    echo "NAS_DEPLOY_DIR must be a plain absolute path with no trailing slash: '$NAS_DEPLOY_DIR'" >&2
    exit 1
fi
D="$NAS_DEPLOY_DIR/pwa/current"

remote() {
    if [[ "$MODE" == "--dry-run" ]]; then
        printf '    ssh %s "%s"\n' "$NAS_SSH" "$1"
    else
        ssh "$NAS_SSH" "$1"
    fi
}

if [[ "$MODE" == "--rollback" ]]; then
    echo "==> Rolling back $D to the previous release"
    # A second rollback swaps back again: the release being replaced becomes .prev.
    ssh "$NAS_SSH" \
        "set -e; test -d '$D.prev' || { echo 'no previous release at $D.prev' >&2; exit 1; }; \
         rm -rf '$D.failed'; mv '$D' '$D.failed'; mv '$D.prev' '$D'; mv '$D.failed' '$D.prev'"
    echo "==> Rolled back. No container restart needed: the backend reads the folder per request."
    exit 0
fi

if [[ -z "${PWA_BASE_PATH:-}" ]]; then
    echo "==> Reading PWA_BASE_PATH from $NAS_SSH:$NAS_DEPLOY_DIR/.env"
    PWA_BASE_PATH="$(ssh "$NAS_SSH" "sed -n 's/^PWA_BASE_PATH=//p' '$NAS_DEPLOY_DIR/.env'" \
        | tail -n 1 | tr -d "\r\"'")"
fi
# Same rule as the backend's validator (app/config.py), so a value the backend would
# refuse at startup is refused here before a build is wasted on it.
if [[ ! "$PWA_BASE_PATH" =~ ^(/[A-Za-z0-9_-][A-Za-z0-9._-]*)+$ ]]; then
    echo "PWA_BASE_PATH is unset or malformed ('$PWA_BASE_PATH')." >&2
    echo "Set it in $NAS_DEPLOY_DIR/.env, e.g. PWA_BASE_PATH=/countscore, and recreate the" >&2
    echo "api container (see the backend-deploy skill, 'Changing one variable in place')." >&2
    exit 1
fi

cd "$ROOT"

echo "==> Building the PWA for $PWA_BASE_PATH/"
# No BACKEND_URL: the backend is a user setting, never baked into a published build.
flutter build web --release --no-tree-shake-icons --base-href="$PWA_BASE_PATH/"

echo "==> Checking build/web"
# Everything under web/ is published. A stray note or instructions file must
# not reach a public URL again (web/CLAUDE.md did, until 2026-09-13).
LEAKS="$(find build/web -iname '*.md')"
if [[ -n "$LEAKS" ]]; then
    echo "Refusing to publish: markdown files in build/web:" >&2
    echo "$LEAKS" >&2
    exit 1
fi
for f in index.html main.dart.js sqlite3.wasm drift_worker.js; do
    if [[ ! -s "build/web/$f" ]]; then
        echo "Refusing to publish: build/web/$f is missing or empty" >&2
        exit 1
    fi
done

if [[ "$MODE" == "--dry-run" ]]; then
    echo "==> Dry run: nothing is sent; these are the remote commands"
fi

echo "==> Uploading to $NAS_SSH:$D.new (scp is blocked, so we pipe a tarball via ssh)"
UPLOAD="set -e; rm -rf '$D.new'; mkdir -p '$D.new'; tar -xzf - -C '$D.new'; chmod -R a+rX '$D.new'"
if [[ "$MODE" == "--dry-run" ]]; then
    printf '    tar -C build/web -czf - . | ssh %s "%s"\n' "$NAS_SSH" "$UPLOAD"
else
    tar -C build/web -czf - . | ssh "$NAS_SSH" "$UPLOAD"
fi

echo "==> Swapping the new release in, keeping the previous one as $D.prev"
remote "set -e; if [ -d '$D' ]; then rm -rf '$D.prev'; mv '$D' '$D.prev'; fi; mv '$D.new' '$D'"

if [[ "$MODE" == "--dry-run" ]]; then
    echo "==> Dry run complete, nothing was published"
    exit 0
fi

echo "==> Published $(git rev-parse --short HEAD) to $PUBLIC_URL$PWA_BASE_PATH/"
echo "    Verify:"
echo "      curl -sI $PUBLIC_URL$PWA_BASE_PATH/ | grep -i -e '^HTTP' -e content-security-policy"
echo "      curl -sI $PUBLIC_URL$PWA_BASE_PATH/sqlite3.wasm | grep -i content-type"
