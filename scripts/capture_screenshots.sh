#!/bin/bash

# CountScore - raw store screenshots of one store locale, over ADB.
#
# Switches CountScore alone to the locale's language (per-app language, Android 13+:
# `cmd locale set-app-locales`; the phone's own language is not touched), restarts it,
# then walks you through the eight screens and pulls each capture into
# store_listing/<locale>/raw/. scripts/compose_screenshots.py composes that set, not the
# shared store_listing/assets/screenshots/phone/, for the locale.
#
# Prerequisites: adb in PATH, one device (or ANDROID_SERIAL naming one), CountScore
# installed with the demo data (players and game names can stay the same in every locale).
#
# Usage: scripts/capture_screenshots.sh <store locale>    e.g. ja-JP, ar, fr-FR
#        scripts/capture_screenshots.sh --reset           CountScore back to the phone's language
#
# Then: uv run --script scripts/compose_screenshots.py --locale <store locale>

set -euo pipefail

PACKAGE="com.vemore.countscore"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LISTING="$ROOT/store_listing"

# stem|what the screen must show. The stems are the caption keys of
# store_listing/<locale>/screenshot_captions.txt: a renamed stem needs its caption renamed
# in all ten files, or the composer refuses the set.
SCREENSHOTS=(
    "01_main_screen|Home: the list of games, three or four of them under way or finished"
    "02_player_management|Players: the player list, with the demo players"
    "03_game_types|New game: the game tiles, the seat order and who's playing"
    "04_podium|End of game: the podium and the final totals of a finished game"
    "05_game_board|Board: a game in progress, several rounds, the leader visible"
    "06_customization|A custom game type being created or edited"
    "07_score_entry|Score entry: the keypad sheet open over the board"
    "08_statistics|Statistics: a player's games, wins and rates"
)

usage() {
    echo "usage: $0 <store locale>   (e.g. ja-JP, ar, fr-FR)" >&2
    echo "       $0 --reset          (CountScore back to the phone's language)" >&2
    exit 2
}

die() {
    echo "error: $*" >&2
    exit 1
}

command -v adb > /dev/null || die "adb not found (Android SDK Platform Tools)"

[ $# -eq 1 ] || usage

# More than one device and no ANDROID_SERIAL: adb itself refuses every command, so say
# why once, here, rather than on the first capture.
devices=$(adb devices | awk 'NR > 1 && $2 == "device" { print $1 }')
count=$(printf '%s' "$devices" | grep -c . || true)
[ "$count" -gt 0 ] || die "no device in 'adb devices' (USB debugging, or adb connect <address>)"
if [ "$count" -gt 1 ] && [ -z "${ANDROID_SERIAL:-}" ]; then
    die "several devices; pick one with ANDROID_SERIAL=<serial>: $(echo "$devices" | tr '\n' ' ')"
fi

if [ "$1" = "--reset" ]; then
    adb shell cmd locale set-app-locales "$PACKAGE" --locales ""
    echo "CountScore follows the phone's language again."
    exit 0
fi

locale="$1"
case "$locale" in
    -*) usage ;;
esac
[ -f "$LISTING/$locale/title.txt" ] ||
    die "$locale is not a store locale (a directory of store_listing/ with a title.txt)"

sdk=$(adb shell getprop ro.build.version.sdk | tr -d '\r')
[ "$sdk" -ge 33 ] || die "per-app language needs Android 13 (API 33); the device is API $sdk"
adb shell pm path "$PACKAGE" > /dev/null || die "$PACKAGE is not installed on the device"

# The store locale is a BCP 47 tag already (ja-JP, zh-CN, ar): Android resolves it to the
# app's closest translation (app_ja.arb, app_zh.arb, app_ar.arb).
adb shell cmd locale set-app-locales "$PACKAGE" --locales "$locale"
current=$(adb shell cmd locale get-app-locales "$PACKAGE" | tr -d '\r')
echo "CountScore language: $current"
adb shell am force-stop "$PACKAGE"
adb shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 > /dev/null

out="$LISTING/$locale/raw"
mkdir -p "$out"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo
echo "Capturing $locale into ${out#"$ROOT"/}. Check the UI is in that language before the first one."
echo

kept=0
for entry in "${SCREENSHOTS[@]}"; do
    stem="${entry%%|*}"
    what="${entry#*|}"
    while true; do
        echo "== $stem: $what"
        read -r -p "ENTER to capture, s to skip: " reply
        if [[ $reply =~ ^[Ss]$ ]]; then
            echo "skipped $stem"
            break
        fi
        if ! adb exec-out screencap -p > "$tmp/$stem.png" || [ ! -s "$tmp/$stem.png" ]; then
            echo "capture failed, again"
            continue
        fi
        if command -v file > /dev/null; then
            file -b "$tmp/$stem.png"
        fi
        choice=v
        while [[ $choice =~ ^[Vv]$ ]]; do
            read -r -p "k keep, r retake, v view: " choice
            if [[ $choice =~ ^[Vv]$ ]]; then
                if command -v xdg-open > /dev/null; then
                    xdg-open "$tmp/$stem.png" > /dev/null 2>&1 &
                else
                    echo "no xdg-open; the file is $tmp/$stem.png"
                fi
            fi
        done
        if [[ $choice =~ ^[Kk]$ ]]; then
            mv "$tmp/$stem.png" "$out/$stem.png"
            kept=$((kept + 1))
            echo "saved ${out#"$ROOT"/}/$stem.png"
            break
        fi
    done
done

echo
echo "$kept of ${#SCREENSHOTS[@]} captures kept in ${out#"$ROOT"/}."
# A capture from an earlier session under a stem no longer listed would be composed too.
for f in "$out"/*.png; do
    [ -e "$f" ] || continue
    name=$(basename "$f" .png)
    known=0
    for entry in "${SCREENSHOTS[@]}"; do
        [ "${entry%%|*}" = "$name" ] && known=1
    done
    [ "$known" -eq 1 ] || echo "warning: ${f#"$ROOT"/} is not in this script's list; delete it or caption it"
done
echo "Next: uv run --script scripts/compose_screenshots.py --locale $locale"
echo "Back to the phone's language: scripts/capture_screenshots.sh --reset"
