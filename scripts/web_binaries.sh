#!/bin/bash

# CountScore - check that the two committed web/ binaries match pubspec.lock.
#
# web/drift_worker.js and web/sqlite3.wasm are tracked so a fresh clone can run the
# PWA without fetching anything, and they must follow the versions the lock resolves.
# Nothing used to compare them: Dependabot #43 bumped drift and merged with five green
# checks and the previous worker still committed, and sqlite3 is transitive, so it
# drifts with no pull request at all.
#
# The two binaries have different sources:
#   - drift_worker.js ships prebuilt at the drift package root, so it is compared
#     offline against $PUB_CACHE/hosted/pub.dev/drift-<locked version>/
#   - sqlite3.wasm is a GitHub release asset, not a file in any package, so the
#     offline check is web/sqlite3.wasm.sha256 next to it: a real `sha256sum -c`
#     file that also records the version it was downloaded for.
#
# The comparison is always against the version in pubspec.lock, never against
# whatever the last `pub get` happened to resolve.
#
# Exit codes: 0 both match - 1 a binary, a digest or a recorded version disagrees
#             2 usage - 3 environment (lock, pub cache, curl, download)
#
# Usage:
#   scripts/web_binaries.sh                     offline check (default)
#   scripts/web_binaries.sh --fetch             also compare the wasm to upstream
#   scripts/web_binaries.sh --refresh           bring both binaries up to the lock
#   scripts/web_binaries.sh --refresh --fetch   same (the refresh always downloads)
#
# A refresh must be followed by the web e2e run (.llmwiki/Testing.md).

set -uo pipefail

MODE="check"
FETCH=0
while [ $# -gt 0 ]; do
    case "$1" in
        --check) MODE="check" ;;
        --refresh) MODE="refresh" ;;
        --fetch) FETCH=1 ;;
        -h | --help) sed -n '3,30p' "$0"; exit 0 ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
    shift
done

ROOT="$(cd "$(dirname "$0")/.." && pwd)" || exit 3
cd "$ROOT" || exit 3

LOCK="pubspec.lock"
WORKER="web/drift_worker.js"
WASM="web/sqlite3.wasm"
SUMS="web/sqlite3.wasm.sha256"
RELEASES="https://github.com/simolus3/sqlite3.dart/releases/download"

# `--refresh` names itself in every exit-1 message: the fix is never left to guesswork.
FIXUP="fix: scripts/web_binaries.sh --refresh, then run the web e2e (.llmwiki/Testing.md)"

found=0   # a real disagreement -> exit 1
envbad=0  # could not check     -> exit 3

say()  { printf '%-6s %s\n' "$1" "$2"; }
note() { say "ok" "$1"; }
fail() { say "FAIL" "$1" >&2; found=1; }
# envmsg only prints: a function whose output is captured runs in a subshell, where
# setting envbad would be lost, so those callers raise it themselves.
envmsg() { say "ERROR" "$1" >&2; }
envf() { envmsg "$1"; envbad=1; }
fatal() { envmsg "$1"; exit 3; }

# ---------------------------------------------------------------- pubspec.lock

[ -r "$LOCK" ] || fatal "$LOCK is unreadable from $ROOT"

lock_version() {  # package -> version, empty if the block or the key is absent
    awk -v pkg="$1" '
        $0 == "  " pkg ":" || $0 == "  \"" pkg "\":" { inblock = 1; next }
        /^[^ ]/     { inblock = 0 }
        /^  [^ ]/   { inblock = 0 }
        inblock && $1 == "version:" { gsub(/"/, "", $2); print $2; exit }
    ' "$LOCK"
}

# Every version is interpolated into a path and a URL: accept nothing exotic.
checked_version() {  # package -> validated version, or fatal
    local pkg="$1" ver
    ver="$(lock_version "$pkg")"
    case "$ver" in
        "") fatal "no version for '$pkg' in $LOCK - is the dependency still there?" ;;
        *[!0-9A-Za-z.+-]*) fatal "implausible version for '$pkg' in $LOCK: '$ver'" ;;
    esac
    printf '%s\n' "$ver"
}

DRIFT_VERSION="$(checked_version drift)" || exit 3
SQLITE3_VERSION="$(checked_version sqlite3)" || exit 3

# ------------------------------------------------------- drift package root

# Cache first, and only the locked version: the point is to compare against what
# the lock says, not against whatever .dart_tool was last generated from. The
# fallback keeps the check working wherever subosito/flutter-action puts its cache.
drift_root() {
    local ver="$1" cache root uri
    cache="${PUB_CACHE:-$HOME/.pub-cache}"
    root="$cache/hosted/pub.dev/drift-$ver"
    if [ -d "$root" ]; then
        printf '%s\n' "$root"
        return 0
    fi
    if [ ! -d "$cache/hosted/pub.dev" ]; then
        envmsg "no pub cache at $cache/hosted/pub.dev - run 'flutter pub get', or set PUB_CACHE"
        return 1
    fi
    uri="$(awk '
        /"name"[[:space:]]*:[[:space:]]*"drift"[[:space:]]*,?[[:space:]]*$/ { want = 1; next }
        want && /"rootUri"/ {
            sub(/^[^:]*:[[:space:]]*"/, ""); sub(/"[[:space:]]*,?[[:space:]]*$/, "")
            print; exit
        }
    ' .dart_tool/package_config.json 2>/dev/null)"
    case "$uri" in
        file:///*)
            root="${uri#file://}"
            # Accepted only if it really is the locked version, never as a "close enough".
            if [ "$(basename "$root")" = "drift-$ver" ] && [ -d "$root" ]; then
                printf '%s\n' "$root"
                return 0
            fi
            ;;
    esac
    envmsg "no drift-$ver in $cache/hosted/pub.dev - run 'flutter pub get', or set PUB_CACHE"
    return 1
}

# ---------------------------------------------------------------- the worker

check_worker() {
    local root src
    root="$(drift_root "$DRIFT_VERSION")" || { envbad=1; return 0; }  # already reported
    src="$root/drift_worker.js"
    if [ ! -f "$src" ]; then
        envf "no drift_worker.js at the drift package root ($src) - drift $DRIFT_VERSION may not ship one"
        return 0
    fi
    if [ ! -f "$WORKER" ]; then
        fail "$WORKER is missing; drift $DRIFT_VERSION ships it at $src"
        say "" "$FIXUP" >&2
        return 0
    fi
    if ! cmp -s "$WORKER" "$src"; then
        fail "$WORKER does not match drift $DRIFT_VERSION"
        say "" "committed: $WORKER ($(wc -c < "$WORKER" | tr -d ' ') B)" >&2
        say "" "expected:  $src ($(wc -c < "$src" | tr -d ' ') B)" >&2
        say "" "$FIXUP" >&2
        return 0
    fi
    note "drift_worker.js matches drift $DRIFT_VERSION"
}

# ------------------------------------------------------------------ the wasm

# `# version:` is its own key rather than something scraped out of `# source:`,
# and the two are cross-checked, so a half-finished hand edit is its own error.
sums_field() { sed -n "s|^# $1: *||p" "$SUMS" | head -1; }
sums_digest() { sed -n 's/^\([0-9a-f]\{64\}\)  *.*$/\1/p' "$SUMS" | head -1; }
# The path column is what makes `sha256sum -c web/sqlite3.wasm.sha256` work by hand
# from the repository root, with no script at all: it has to stay $WASM.
sums_path() { sed -n 's/^[0-9a-f]\{64\}  *//p' "$SUMS" | head -1; }

wasm_url() { printf '%s/sqlite3-%s/sqlite3.wasm\n' "$RELEASES" "$1"; }

check_wasm() {
    local recorded source_url digest actual
    if [ ! -f "$WASM" ]; then
        fail "$WASM is missing; it is a release asset, $(wasm_url "$SQLITE3_VERSION")"
        say "" "$FIXUP" >&2
        return 0
    fi
    if [ ! -f "$SUMS" ]; then
        fail "$SUMS is missing - the wasm cannot be checked without it"
        say "" "$FIXUP" >&2
        return 0
    fi
    recorded="$(sums_field version)"
    source_url="$(sums_field source)"
    digest="$(sums_digest)"
    if [ -z "$recorded" ] || [ -z "$source_url" ] || [ -z "$digest" ] || [ "$(sums_path)" != "$WASM" ]; then
        fail "$SUMS is unparseable - it needs a '# version:', a '# source:' and one '<sha256>  $WASM' line"
        say "" "$FIXUP" >&2
        return 0
    fi
    if [ "$source_url" != "$(wasm_url "$recorded")" ]; then
        fail "$SUMS disagrees with itself: '# version: $recorded' but '# source: $source_url'"
        say "" "$FIXUP" >&2
        return 0
    fi
    if [ "$recorded" != "$SQLITE3_VERSION" ]; then
        fail "$WASM is recorded for sqlite3 $recorded, $LOCK resolves $SQLITE3_VERSION"
        say "" "sqlite3 is transitive: it moves with no Dependabot pull request at all" >&2
        say "" "$FIXUP" >&2
        return 0
    fi
    actual="$(sha256sum "$WASM" | cut -d' ' -f1)"
    if [ "$actual" != "$digest" ]; then
        fail "$WASM does not match the digest recorded in $SUMS"
        say "" "committed: $actual" >&2
        say "" "recorded:  $digest" >&2
        say "" "$FIXUP" >&2
        return 0
    fi
    note "sqlite3.wasm matches sqlite3 $SQLITE3_VERSION ($digest)"
}

# ------------------------------------------------------------ the download

# Validated in a temp dir and only then copied: a failed or truncated download can
# never reach web/. `cp`, never `mv` - .claude/hooks/parse_command.py refuses an mv
# whose operands name either binary, destination included.
download_wasm() {  # version, destination file -> 0, or 1 after raising envbad
    local ver="$1" dest="$2" url tmp magic rc=0
    url="$(wasm_url "$ver")"
    command -v curl >/dev/null 2>&1 || { envf "curl is not installed - cannot reach $url"; return 1; }
    tmp="$(mktemp -d)" || { envf "cannot create a temporary directory"; return 1; }
    if ! curl -fsSL --proto '=https' --tlsv1.2 --retry 3 --retry-all-errors --max-time 180 \
        -o "$tmp/sqlite3.wasm" "$url"; then
        envf "download failed: $url"
        rc=1
    else
        # An error page or an HTML redirect is a perfectly valid file; a wasm module is not.
        magic="$(head -c 4 "$tmp/sqlite3.wasm" | od -An -tx1 | tr -d ' \n')"
        if [ "$magic" != "0061736d" ]; then
            envf "what $url served is not a WebAssembly module (first bytes: $magic)"
            rc=1
        elif ! cp "$tmp/sqlite3.wasm" "$dest"; then
            envf "cannot write $dest"
            rc=1
        fi
    fi
    rm -rf "$tmp"
    return "$rc"
}

fetch_wasm() {  # compare the committed bytes with what GitHub serves today
    local tmp upstream actual
    [ -f "$WASM" ] || return 0  # already reported by check_wasm
    tmp="$(mktemp -d)" || { envf "cannot create a temporary directory"; return 0; }
    if download_wasm "$SQLITE3_VERSION" "$tmp/upstream.wasm"; then
        upstream="$(sha256sum "$tmp/upstream.wasm" | cut -d' ' -f1)"
        actual="$(sha256sum "$WASM" | cut -d' ' -f1)"
        if [ "$upstream" != "$actual" ]; then
            fail "$WASM differs from the sqlite3-$SQLITE3_VERSION asset GitHub serves today"
            say "" "committed: $actual" >&2
            say "" "upstream:  $upstream" >&2
            say "" "$FIXUP" >&2
        else
            note "sqlite3.wasm matches the upstream sqlite3-$SQLITE3_VERSION asset"
        fi
    fi
    rm -rf "$tmp"
}

# ------------------------------------------------------------------ refresh

refresh() {
    local root src digest
    root="$(drift_root "$DRIFT_VERSION")" || { envbad=1; return 0; }
    src="$root/drift_worker.js"
    if [ ! -f "$src" ]; then
        envf "no drift_worker.js at the drift package root ($src)"
        return 0
    fi
    if cp "$src" "$WORKER"; then
        note "drift_worker.js <- $src"
    else
        envf "cannot write $WORKER"
        return 0
    fi

    download_wasm "$SQLITE3_VERSION" "$WASM" || return 0
    note "sqlite3.wasm <- $(wasm_url "$SQLITE3_VERSION")"

    digest="$(sha256sum "$WASM" | cut -d' ' -f1)"
    cat > "$SUMS" <<EOF
# $WASM — checked by scripts/web_binaries.sh, refreshed by --refresh.
# source: $(wasm_url "$SQLITE3_VERSION")
# version: $SQLITE3_VERSION
$digest  $WASM
EOF
    note "$SUMS rewritten for sqlite3 $SQLITE3_VERSION"
    echo
    echo "Refreshed against $LOCK. Run the web e2e before committing (.llmwiki/Testing.md)."
}

# --------------------------------------------------------------------- run

echo "pubspec.lock: drift $DRIFT_VERSION, sqlite3 $SQLITE3_VERSION"

if [ "$MODE" = "refresh" ]; then
    refresh
else
    # Both binaries are always checked: one Dependabot week can move both packages,
    # and one run should print both problems rather than the first one.
    check_worker
    check_wasm
    [ "$FETCH" = 1 ] && fetch_wasm
fi

[ "$found" = 1 ] && exit 1
[ "$envbad" = 1 ] && exit 3
exit 0
