#!/usr/bin/env bash
# Carry a real CountScore database from an old debuggable install to a clean release install,
# for the release-android §5 upgrade test.
#
#   device_db_roundtrip.sh [-s SERIAL] pull [OUT.db]
#   device_db_roundtrip.sh [-s SERIAL] push [IN.db]
#
#   pull  read databases/countscore.db (plus -wal and -journal when present) out of the
#         installed app with `run-as`, fold the WAL into one self-contained file with SQLite's
#         backup API, check its integrity and print its user_version.
#         Default OUT: build/device_db/countscore.db (gitignored — it is real personal data).
#   push  copy that file to /sdcard/Download/countscore-upgrade-test.db, where Settings →
#         Import (DatabaseService.importDatabase) picks it up as a raw .db.
#
# The device is -s SERIAL or $ANDROID_SERIAL, and one of them is required: never "the only
# device adb sees", which is how a stale wireless-debugging address tests the wrong phone.
#
# `run-as` only works on a debuggable build (debug or profile). A Play install and the release
# APK are not debuggable, and pull says so instead of producing an empty file.
#
# $ADB overrides the adb binary (the tests put a fake one there). Needs python3 for the WAL
# fold, which the sqlite3 shipped in platform-tools is too old to be trusted with.

set -euo pipefail

PKG="com.vemore.countscore"
DB="countscore.db"
REMOTE="/sdcard/Download/countscore-upgrade-test.db"
ADB="${ADB:-adb}"

usage() { sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
die() { echo "device_db_roundtrip: $*" >&2; exit 1; }

serial="${ANDROID_SERIAL:-}"
if [[ "${1:-}" == "-s" ]]; then
    [[ $# -ge 2 ]] || usage
    serial="$2"
    shift 2
fi
[[ $# -ge 1 ]] || usage
cmd="$1"
shift
[[ -n "$serial" ]] || die "no device: pass -s SERIAL or set ANDROID_SERIAL (adb devices -l)"
export ANDROID_SERIAL="$serial"

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
default_db="$root/build/device_db/$DB"

state="$("$ADB" get-state 2>/dev/null || true)"
[[ "$state" == "device" ]] || die "$serial is not an attached device (state: ${state:-none})"

pull() {
    local out="${1:-$default_db}" f
    "$ADB" shell run-as "$PKG" true >/dev/null 2>&1 \
        || die "run-as $PKG failed: the installed build is not debuggable (a Play or release install). Install a debug build of the old version first, and use it for a while."

    # Stop the app so nothing writes while the files are read. A killed process leaves its WAL
    # behind uncheckpointed, which is why the -wal file is pulled and folded below.
    "$ADB" shell am force-stop "$PKG"

    work="$(mktemp -d)"
    trap 'rm -rf "$work"' EXIT

    local listing
    listing="$("$ADB" shell run-as "$PKG" ls databases/ | tr -d '\r')"
    grep -qx "$DB" <<<"$listing" || die "no databases/$DB in $PKG — has the app been opened once?"

    for f in "$DB" "$DB-wal" "$DB-journal"; do
        grep -qx "$f" <<<"$listing" || continue
        "$ADB" exec-out run-as "$PKG" cat "databases/$f" >"$work/$f"
        echo "pulled databases/$f ($(wc -c <"$work/$f") bytes)"
    done
    [[ -s "$work/$DB" ]] || die "databases/$DB came back empty"

    mkdir -p "$(dirname "$out")"
    rm -f "$out" "$out-wal" "$out-shm" "$out-journal"
    python3 - "$work/$DB" "$out" <<'PY'
import sqlite3, sys
src, dst = sys.argv[1], sys.argv[2]
# Opening the pulled file next to its -wal replays the WAL; backup() writes every committed
# page into one standalone file, and DELETE mode leaves no -wal beside it.
s, d = sqlite3.connect(src), sqlite3.connect(dst)
s.backup(d)
s.close()
d.execute("PRAGMA journal_mode=DELETE")
check = d.execute("PRAGMA integrity_check").fetchone()[0]
version = d.execute("PRAGMA user_version").fetchone()[0]
tables = {r[0] for r in d.execute("SELECT name FROM sqlite_master WHERE type='table'")}
counts = {t: d.execute(f'SELECT COUNT(*) FROM "{t}"').fetchone()[0]
          for t in ("games", "players", "scores") if t in tables}
d.close()
if check != "ok":
    sys.exit(f"integrity_check: {check}")
print(f"user_version={version}")
print(" ".join(f"{t}={n}" for t, n in counts.items()))
PY
    echo "wrote $out"
}

push() {
    local in="${1:-$default_db}"
    [[ -f "$in" ]] || die "$in does not exist — run pull first"
    [[ "$(head -c 15 "$in")" == "SQLite format 3" ]] || die "$in is not an SQLite database"
    "$ADB" push "$in" "$REMOTE" >/dev/null
    # Make it visible to the picker's Recent/Downloads views at once; harmless where ignored.
    "$ADB" shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
        -d "file://$REMOTE" >/dev/null 2>&1 || true
    echo "pushed $in -> $REMOTE"
    echo "next: Settings → Import → Downloads → $(basename "$REMOTE"), confirm, reopen the app"
}

case "$cmd" in
    pull) pull "$@" ;;
    push) push "$@" ;;
    *) usage ;;
esac
