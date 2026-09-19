#!/bin/bash

# CountScore - build the PWA so that it fetches nothing from a Google host.
#
# A stock `flutter build web` makes every visitor's browser call Google twice over:
# CanvasKit from www.gstatic.com, and fonts from fonts.gstatic.com — Roboto on every
# start (the engine's default fallback), then a Noto font whenever a glyph is missing
# from Nunito (Chinese, Japanese, Arabic, Devanagari, emoji...). This script is the one
# way to build a publishable PWA; it does four things:
#
#   1. flutter build web --release --no-tree-shake-icons --no-web-resources-cdn
#      (CanvasKit is served from build/web/canvaskit/, `useLocalCanvasKit: true`);
#      extra arguments (--base-href=..., --dart-define=...) are passed through;
#   2. web/flutter_bootstrap.js, the one customised loader file, points the engine's
#      fontFallbackBaseUrl at "fallback-fonts/";
#   3. every font file the compiled engine can ask for — read from build/web/main.dart.js
#      itself, so the list always matches the SDK that built it — is copied to
#      build/web/fallback-fonts/<same path>, next to the licences committed in
#      web/fallback-fonts/ (Noto: OFL 1.1; Roboto: Apache 2.0);
#   4. the service worker (web/service_worker.js) is armed: flutter_bootstrap.js registers
#      it, and it receives the build id and the digest of every file it precaches, so a
#      deploy replaces its cache as a whole (.llmwiki/Web.md, "Offline and updates").
#
# The fonts are downloaded from fonts.gstatic.com by the machine that builds (never by a
# visitor), once: the paths are versioned and immutable, so they are kept in a cache
# ($COUNTSCORE_FONT_CACHE, default ~/.cache/countscore/fallback-fonts; CI caches it).
# About 22 MB for all 725 files; a visitor downloads only the few it needs, lazily.
#
# scripts/check_web_build.sh refuses a build that skipped any of the four.
#
# Usage: scripts/build_web.sh [flutter build web arguments...]
# Exit:  0 built - 1 build or download failed - 3 environment (curl, flutter, python3)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build/web"
UPSTREAM="https://fonts.gstatic.com/s/"
CACHE="${COUNTSCORE_FONT_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/countscore/fallback-fonts}"
# The pattern check_web_build.sh uses too: a quoted, versioned Google Fonts path.
FONT_PATH_RE='"[a-z0-9]+/v[0-9]+/[A-Za-z0-9_.-]+\.(woff2|ttf|otf)"'

for tool in flutter curl python3; do
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

echo "==> Arming the service worker"
# Exactly one worker: Flutter's flutter_service_worker.js is a stub that unregisters itself,
# which web/flutter_bootstrap.js no longer registers; drop it so nothing can.
rm -f "$BUILD/flutter_service_worker.js"
sed -i 's|^const countscoreServiceWorker = false; // @service-worker$|const countscoreServiceWorker = true; // @service-worker|' \
    "$BUILD/flutter_bootstrap.js"
# The worker names its cache after the build and checks every file it caches against the
# build's digest. Last, so the build id covers every other file, the loader above included.
python3 - "$BUILD" <<'PY'
import hashlib, json, pathlib, re, sys

build = pathlib.Path(sys.argv[1])
worker = build / "service_worker.js"
digests = {}
for f in sorted(p for p in build.rglob("*") if p.is_file() and p != worker):
    digests[f.relative_to(build).as_posix()] = hashlib.sha256(f.read_bytes()).hexdigest()

def skipped(path):
    # Not precached: the worker itself, build bookkeeping, debug symbols, the checksum of
    # a committed binary, CanvasKit (ON_DEMAND) and the fallback fonts (cached when used).
    return (path in (".last_build_id", "sqlite3.wasm.sha256")
            or path.endswith(".symbols")
            or path.startswith(("canvaskit/", "fallback-fonts/")))

precache = {p: d for p, d in digests.items() if not skipped(p)}
on_demand = {p: d for p, d in digests.items()
             if p.startswith("canvaskit/") and p.endswith((".js", ".wasm"))}
build_id = hashlib.sha256(
    "".join(f"{d}  {p}\n" for p, d in digests.items()).encode()).hexdigest()[:16]

source = worker.read_text()
for marker, value in (("build-id", json.dumps(build_id)),
                      ("precache", json.dumps(precache, indent=1)),
                      ("on-demand", json.dumps(on_demand, indent=1))):
    source, n = re.subn(rf"^(const \w+ = ).*; // @{marker}$",
                        lambda m: f"{m.group(1)}{value}; // @{marker}", source, flags=re.M)
    if n != 1:
        sys.exit(f"build_web.sh: no '// @{marker}' line in {worker}")
worker.write_text(source)
print(f"    build {build_id}: {len(precache)} files precached, "
      f"{sum((build / p).stat().st_size for p in precache) // 1024} KB")
PY

echo "==> build/web is built with no Google-hosted resource"
