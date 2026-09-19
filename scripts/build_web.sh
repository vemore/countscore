#!/bin/bash

# CountScore - build the PWA so that it fetches nothing from a Google host.
#
# A stock `flutter build web` makes every visitor's browser call Google twice over:
# CanvasKit from www.gstatic.com, and fonts from fonts.gstatic.com — Roboto on every
# start (the engine's default fallback), then a Noto font whenever a glyph is missing
# from Nunito (Chinese, Japanese, Arabic, Devanagari, emoji...). This script is the one
# way to build a publishable PWA; it does three things:
#
#   1. flutter build web --release --no-tree-shake-icons --no-web-resources-cdn
#      (CanvasKit is served from build/web/canvaskit/, `useLocalCanvasKit: true`);
#      extra arguments (--base-href=..., --dart-define=...) are passed through;
#   2. web/flutter_bootstrap.js, the one customised loader file, points the engine's
#      fontFallbackBaseUrl at "fallback-fonts/";
#   3. every font file the compiled engine can ask for — read from build/web/main.dart.js
#      itself, so the list always matches the SDK that built it — is copied to
#      build/web/fallback-fonts/<same path>, next to the licences committed in
#      web/fallback-fonts/ (Noto: OFL 1.1; Roboto: Apache 2.0).
#
# The fonts are downloaded from fonts.gstatic.com by the machine that builds (never by a
# visitor), once: the paths are versioned and immutable, so they are kept in a cache
# ($COUNTSCORE_FONT_CACHE, default ~/.cache/countscore/fallback-fonts; CI caches it).
# About 22 MB for all 725 files; a visitor downloads only the few it needs, lazily.
#
# scripts/check_web_build.sh refuses a build that skipped any of the three.
#
# Usage: scripts/build_web.sh [flutter build web arguments...]
# Exit:  0 built - 1 build or download failed - 3 environment (curl, flutter)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build/web"
UPSTREAM="https://fonts.gstatic.com/s/"
CACHE="${COUNTSCORE_FONT_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/countscore/fallback-fonts}"
# The pattern check_web_build.sh uses too: a quoted, versioned Google Fonts path.
FONT_PATH_RE='"[a-z0-9]+/v[0-9]+/[A-Za-z0-9_.-]+\.(woff2|ttf|otf)"'

for tool in flutter curl; do
    command -v "$tool" > /dev/null || { echo "build_web.sh: $tool not found" >&2; exit 3; }
done

cd "$ROOT"

# --no-tree-shake-icons: game-type icons are built from database codepoints.
# No BACKEND_URL here: the backend is a user setting, never baked into a published build.
flutter build web --release --no-tree-shake-icons --no-web-resources-cdn "$@"

mapfile -t FONTS < <(grep -oE "$FONT_PATH_RE" "$BUILD/main.dart.js" | tr -d '"' | sort -u)
# Roboto alone would mean the engine's fallback table moved out of main.dart.js:
# refuse rather than publish a build whose fallback fonts would all 404.
if [ "${#FONTS[@]}" -lt 100 ]; then
    echo "build_web.sh: only ${#FONTS[@]} fallback font paths found in main.dart.js;" >&2
    echo "the engine's font table changed shape — see .llmwiki/Web.md" >&2
    exit 1
fi

missing=()
for f in "${FONTS[@]}"; do
    [ -s "$CACHE/$f" ] || missing+=("$f")
done
if [ "${#missing[@]}" -gt 0 ]; then
    echo "==> Downloading ${#missing[@]} of ${#FONTS[@]} fallback fonts into $CACHE"
    fetch_one() {  # path -> $CACHE/path, atomically, only if it is a real font
        local dest="$CACHE/$1" tmp
        mkdir -p "$(dirname "$dest")"
        tmp="$(mktemp "$dest.XXXXXX")"
        if curl -fsSL --retry 3 --retry-all-errors -o "$tmp" "$UPSTREAM$1" \
            && [ "$(head -c 4 "$tmp")" = "wOF2" ]; then
            mv "$tmp" "$dest"
        else
            rm -f "$tmp"
            echo "build_web.sh: could not fetch $UPSTREAM$1" >&2
            return 1
        fi
    }
    export -f fetch_one
    export CACHE UPSTREAM
    printf '%s\n' "${missing[@]}" | xargs -P 16 -I{} bash -c 'fetch_one "$1"' _ {} \
        || { echo "build_web.sh: fallback font download failed" >&2; exit 1; }
fi

echo "==> Copying ${#FONTS[@]} fallback fonts into build/web/fallback-fonts/"
# Next to OFL.txt and LICENSE-Apache-2.0.txt, which Flutter copied from web/fallback-fonts/:
# the licences travel with the fonts, as the OFL asks.
for f in "${FONTS[@]}"; do
    mkdir -p "$BUILD/fallback-fonts/$(dirname "$f")"
    cp "$CACHE/$f" "$BUILD/fallback-fonts/$f"
done

echo "==> build/web is built with no Google-hosted resource"
