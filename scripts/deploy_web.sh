#!/bin/bash
# Build and publish the CountScore PWA to a Synology Web Station folder, served
# under a sub-path of an existing site.
#
# The host and the folder are deliberately NOT in this file: they are one
# person's infrastructure, and the repository is public. Put them in
# scripts/deploy_web.env (gitignored) — copy scripts/deploy_web.env.example —
# or export the same variables in the environment.
#
# Prereqs (one-time, see the web-deploy skill):
#   - an SSH alias for the NAS, configured in ~/.ssh/config, whose user can
#     write to the parent of $WEB_NAS_DIR
#   - Web Station serving $WEB_NAS_DIR at $WEB_BASE_HREF over TLS
#
# Usage:
#   scripts/deploy_web.sh               # build + check + publish current tree
#   scripts/deploy_web.sh --dry-run     # build + check, print the remote commands
#   scripts/deploy_web.sh --rollback    # swap the previous release back in
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/scripts/deploy_web.env"
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
: "${NAS_SSH:?set NAS_SSH in scripts/deploy_web.env (see deploy_web.env.example)}"
: "${WEB_NAS_DIR:?set WEB_NAS_DIR in scripts/deploy_web.env (see deploy_web.env.example)}"
: "${WEB_BASE_HREF:?set WEB_BASE_HREF in scripts/deploy_web.env (see deploy_web.env.example)}"
WEB_PUBLIC_URL="${WEB_PUBLIC_URL:-<your public URL>}"

# The folder is interpolated into a remote shell and has rm -rf run on its
# .new/.prev siblings: accept only a plain absolute path at least two levels deep.
if [[ ! "$WEB_NAS_DIR" =~ ^/[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)+$ ]]; then
    echo "WEB_NAS_DIR must be an absolute path, two levels deep or more, of [A-Za-z0-9._-] segments with no trailing slash: '$WEB_NAS_DIR'" >&2
    exit 1
fi
# Flutter rejects a base href that does not start and end with a slash.
if [[ ! "$WEB_BASE_HREF" =~ ^/([A-Za-z0-9._-]+/)*$ ]]; then
    echo "WEB_BASE_HREF must start and end with '/', e.g. /countscore/: '$WEB_BASE_HREF'" >&2
    exit 1
fi

D="$WEB_NAS_DIR"

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
    echo "==> Rolled back. Check $WEB_PUBLIC_URL"
    exit 0
fi

cd "$ROOT"

echo "==> Building the PWA for $WEB_BASE_HREF"
# No BACKEND_URL: the backend is a user setting, never baked into a published build.
flutter build web --release --no-tree-shake-icons --base-href="$WEB_BASE_HREF"

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
    echo "==> Dry run: would stream build/web to $NAS_SSH and run:"
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

echo "==> Published $(git rev-parse --short HEAD) to $WEB_PUBLIC_URL"
echo "    Check that sqlite3.wasm is served as application/wasm:"
echo "      curl -sI $WEB_PUBLIC_URL/sqlite3.wasm | grep -i content-type"
