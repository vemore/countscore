#!/bin/bash

# CountScore - refuse to publish a PWA build that should not reach a public URL.
#
# Everything under web/ is copied into build/web/, and build/web/ is published as is,
# by scripts/deploy_web.sh (the backend's own host) and by .github/workflows/deploy-pages.yml
# (GitHub Pages). Both run this one script, so the two publishing paths cannot drift apart.
#
# It refuses:
#   - any Markdown file in the build: a stray note or an instructions file must not reach
#     a public URL again (web/CLAUDE.md did, until 2026-09-13). `assets/assets/` is
#     excluded because pubspec.yaml declares what goes there: the shipped game rules are
#     Markdown on purpose (.llmwiki/I18n.md), and publishing them is the point;
#   - a build missing one of the files the PWA cannot start without.
#
# It does not compare the committed web/ binaries with pubspec.lock: that is
# scripts/web_binaries.sh, which needs the pub cache and runs before the build.
#
# Usage: scripts/check_web_build.sh [build dir]     (default: build/web)
# Exit:  0 publishable - 1 refused - 2 usage

set -uo pipefail

if [ $# -gt 1 ]; then
    echo "Usage: check_web_build.sh [build dir]" >&2
    exit 2
fi
DIR="${1:-build/web}"
if [ ! -d "$DIR" ]; then
    echo "Refusing to publish: $DIR is not a directory (build first)" >&2
    exit 1
fi
DIR="${DIR%/}"

status=0

LEAKS="$(find "$DIR" -iname '*.md' -not -path "$DIR/assets/assets/*")"
if [ -n "$LEAKS" ]; then
    echo "Refusing to publish: markdown files in $DIR:" >&2
    echo "$LEAKS" >&2
    status=1
fi

for f in index.html main.dart.js sqlite3.wasm drift_worker.js; do
    if [ ! -s "$DIR/$f" ]; then
        echo "Refusing to publish: $DIR/$f is missing or empty" >&2
        status=1
    fi
done

[ "$status" -eq 0 ] && echo "$DIR is publishable"
exit "$status"
