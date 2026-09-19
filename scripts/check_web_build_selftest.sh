#!/bin/bash

# CountScore - self-test of scripts/check_web_build.sh.
#
# That script is the last thing between build/web/ and a public URL, for both
# publishing paths (deploy_web.sh and the GitHub Pages workflow). A check that
# silently stopped refusing would publish the next stray note, so its refusals are
# pinned here against fixture builds. Needs neither Flutter nor the network; the
# `app` CI job runs it next to the hooks self-test.
#
# Usage: scripts/check_web_build_selftest.sh      (exit 0 = every case behaves)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK="$ROOT/scripts/check_web_build.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

fixture() {  # name -> a minimal publishable build under $TMP/name
    local d="$TMP/$1"
    mkdir -p "$d/assets/assets/rules"
    for f in index.html sqlite3.wasm drift_worker.js; do
        printf 'x' > "$d/$f"
    done
    printf '# rules' > "$d/assets/assets/rules/zapzap.fr.md"
    # What scripts/build_web.sh produces: local CanvasKit, the loader pointed at
    # fallback-fonts/, and every font path the engine names mirrored there.
    printf 'x=A.ef().g()+"roboto/v32/KFOm.woff2";y="notosanssc/v37/k3kC.12.woff2"' > "$d/main.dart.js"
    printf '_flutter.buildConfig = {"useLocalCanvasKit":true};\n_flutter.loader.load({\n  config: {\n    fontFallbackBaseUrl: "fallback-fonts/",\n  },\n});\n' \
        > "$d/flutter_bootstrap.js"
    mkdir -p "$d/canvaskit" "$d/fallback-fonts/roboto/v32" "$d/fallback-fonts/notosanssc/v37"
    printf 'x' > "$d/canvaskit/canvaskit.wasm"
    printf 'wOF2' > "$d/fallback-fonts/roboto/v32/KFOm.woff2"
    printf 'wOF2' > "$d/fallback-fonts/notosanssc/v37/k3kC.12.woff2"
    echo "$d"
}

expect() {  # description, expected exit code, build dir
    "$CHECK" "$3" > /dev/null 2>&1
    local got=$?
    if [ "$got" -eq "$2" ]; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        printf '  FAIL  %s\n        expected exit %s, got %s\n' "$1" "$2" "$got"
    fi
}

d=$(fixture ok)
expect "a clean build, shipped rules included" 0 "$d"
expect "the same build, given with a trailing slash" 0 "$d/"

d=$(fixture leak_root)
printf 'notes' > "$d/CLAUDE.md"
expect "a Markdown file at the root" 1 "$d"

d=$(fixture leak_upper)
printf 'notes' > "$d/NOTES.MD"
expect "an upper-case .MD" 1 "$d"

d=$(fixture leak_nested)
mkdir -p "$d/icons"
printf 'notes' > "$d/icons/README.md"
expect "a Markdown file in a subdirectory" 1 "$d"

d=$(fixture leak_assets)
printf 'notes' > "$d/assets/README.md"
expect "a Markdown file in assets/ but outside assets/assets/" 1 "$d"

for f in index.html main.dart.js sqlite3.wasm drift_worker.js; do
    d=$(fixture "missing_$f")
    rm "$d/$f"
    expect "a missing $f" 1 "$d"
    d=$(fixture "empty_$f")
    : > "$d/$f"
    expect "an empty $f" 1 "$d"
done

expect "no build at all" 1 "$TMP/does-not-exist"

# A build that would make a visitor's browser call Google.
d=$(fixture cdn_canvaskit)
sed -i 's/"useLocalCanvasKit":true//' "$d/flutter_bootstrap.js"
expect "CanvasKit from the CDN (no --no-web-resources-cdn)" 1 "$d"

d=$(fixture no_canvaskit)
rm "$d/canvaskit/canvaskit.wasm"
expect "no local canvaskit.wasm" 1 "$d"

d=$(fixture stock_loader)
sed -i '/fontFallbackBaseUrl/d' "$d/flutter_bootstrap.js"
expect "the stock loader (fonts from fonts.gstatic.com)" 1 "$d"

d=$(fixture no_loader)
rm "$d/flutter_bootstrap.js"
expect "no flutter_bootstrap.js" 1 "$d"

d=$(fixture font_missing)
rm "$d/fallback-fonts/notosanssc/v37/k3kC.12.woff2"
expect "a fallback font the engine names is not mirrored" 1 "$d"

d=$(fixture no_fonts)
rm -rf "$d/fallback-fonts"
expect "no fallback-fonts/ at all (a plain flutter build web)" 1 "$d"

d=$(fixture no_font_table)
printf 'x' > "$d/main.dart.js"
expect "main.dart.js names no font path (the engine's table moved)" 1 "$d"

"$CHECK" a b > /dev/null 2>&1
if [ $? -eq 2 ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "  FAIL  two arguments is not a usage error"; fi

# Both publishing paths must call the check, or the two drift apart again.
for caller in scripts/deploy_web.sh .github/workflows/deploy-pages.yml; do
    if grep -q 'scripts/check_web_build.sh' "$ROOT/$caller"; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "  FAIL  $caller no longer runs scripts/check_web_build.sh"
    fi
done

# Every web build that is published or checked goes through scripts/build_web.sh.
for caller in scripts/deploy_web.sh .github/workflows/deploy-pages.yml .github/workflows/ci.yml; do
    if grep -q 'scripts/build_web.sh' "$ROOT/$caller" && ! grep -qE '^[^#]*flutter build web' "$ROOT/$caller"; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "  FAIL  $caller builds the PWA without scripts/build_web.sh"
    fi
done

# The Pages workflow must also refuse a stale web/ binary, as the `app` CI job does.
if grep -q 'scripts/web_binaries.sh --check' "$ROOT/.github/workflows/deploy-pages.yml"; then
    pass=$((pass + 1))
else
    fail=$((fail + 1))
    echo "  FAIL  deploy-pages.yml no longer runs scripts/web_binaries.sh --check"
fi

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
