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
#   - a build missing one of the files the PWA cannot start without;
#   - a build that would make a visitor's browser call Google (built without
#     scripts/build_web.sh): CanvasKit must come from the build (`useLocalCanvasKit`,
#     canvaskit/canvaskit.wasm), the loader must point fontFallbackBaseUrl at
#     fallback-fonts/, and every font path the compiled engine can request must be
#     there. .llmwiki/Web.md, "Self-hosted web resources".
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

# Self-hosted web resources. Only meaningful once main.dart.js and the loader exist.
if [ -s "$DIR/main.dart.js" ]; then
    if [ ! -s "$DIR/canvaskit/canvaskit.wasm" ]; then
        echo "Refusing to publish: $DIR/canvaskit/canvaskit.wasm is missing (build with scripts/build_web.sh)" >&2
        status=1
    fi
    if ! grep -q '"useLocalCanvasKit":true' "$DIR/flutter_bootstrap.js" 2>/dev/null; then
        echo "Refusing to publish: $DIR/flutter_bootstrap.js loads CanvasKit from Google's CDN (build with --no-web-resources-cdn)" >&2
        status=1
    fi
    if ! grep -q 'fontFallbackBaseUrl: "fallback-fonts/"' "$DIR/flutter_bootstrap.js" 2>/dev/null; then
        echo "Refusing to publish: $DIR/flutter_bootstrap.js does not set fontFallbackBaseUrl to fallback-fonts/ (web/flutter_bootstrap.js)" >&2
        status=1
    fi
    FONTS="$(grep -oE '"[a-z0-9]+/v[0-9]+/[A-Za-z0-9_.-]+\.(woff2|ttf|otf)"' "$DIR/main.dart.js" | tr -d '"' | sort -u)"
    if [ -z "$FONTS" ]; then
        echo "Refusing to publish: no fallback font path found in $DIR/main.dart.js (the engine's font table changed shape)" >&2
        status=1
    fi
    ABSENT=0
    for f in $FONTS; do
        if [ ! -s "$DIR/fallback-fonts/$f" ]; then
            [ "$ABSENT" -lt 3 ] && echo "Refusing to publish: $DIR/fallback-fonts/$f is missing" >&2
            ABSENT=$((ABSENT + 1))
        fi
    done
    if [ "$ABSENT" -gt 0 ]; then
        echo "Refusing to publish: $ABSENT fallback fonts missing (build with scripts/build_web.sh)" >&2
        status=1
    fi
fi

[ "$status" -eq 0 ] && echo "$DIR is publishable"
exit "$status"
