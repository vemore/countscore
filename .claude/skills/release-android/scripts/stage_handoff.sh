#!/usr/bin/env bash
# Stage a verified bundle and a filled-in Play Console brief where a browser agent can reach it.
#
#   .claude/skills/release-android/scripts/stage_handoff.sh <track> [rollout-percent] [optional-tasks]
#
#   track            internal | closed | production
#   rollout-percent  production only, default 20
#   optional-tasks   free text for Part C of the brief, default "none"
#
# Cowork and Claude in Chrome run on the Windows side of this WSL machine, and their file
# upload only sees folders the user grants — so the hand-off goes to the Windows Downloads
# folder, never to a path inside WSL. Run verify_aab.sh first; this script refuses otherwise.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
SKILL="$ROOT/.claude/skills/release-android"
AAB="$ROOT/build/app/outputs/bundle/release/app-release.aab"
NOTES_LIMIT=500

track="${1:?usage: stage_handoff.sh <internal|closed|production> [rollout-percent] [optional-tasks]}"
rollout="${2:-20}"
optional="${3:-none}"

case "$track" in
  internal)   track_label="Internal testing"; track_menu="Testing → Internal testing / Tests → Tests internes" ;;
  closed)     track_label="Closed testing";   track_menu="Testing → Closed testing / Tests → Tests fermés" ;;
  production) track_label="Production";       track_menu="Production" ;;
  *) echo "track must be internal, closed or production" >&2; exit 2 ;;
esac

"$SKILL/scripts/verify_aab.sh" "$AAB"

version_full="$(sed -n 's/^version: *//p' "$ROOT/pubspec.yaml")"
version="${version_full%%+*}"
code="${version_full##*+}"
sha="$(keytool -printcert -jarfile "$AAB" | sed -n 's/^[[:space:]]*SHA256: //p' | head -n1)"

notes_block=""
for locale in en-US fr-FR; do
  notes="$ROOT/store_listing/$locale/release_notes_v$version.txt"
  [[ -f "$notes" ]] || { echo "missing release notes: $notes" >&2; exit 1; }
  chars="$(wc -m <"$notes")"
  (( chars <= NOTES_LIMIT )) || { echo "$notes is $chars characters; Play allows $NOTES_LIMIT" >&2; exit 1; }
  notes_block+="<$locale>"$'\n'"$(cat "$notes")"$'\n'"</$locale>"$'\n'
done

win_user="$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r')"
[[ -n "$win_user" && -d "/mnt/c/Users/$win_user" ]] || { echo "cannot resolve the Windows user folder" >&2; exit 1; }
dir="/mnt/c/Users/$win_user/Downloads/countscore-release-$version_full"
dir_win="C:\\Users\\$win_user\\Downloads\\countscore-release-$version_full"
[[ ! -e "$dir" ]] || { echo "$dir already exists — remove it or bump the version" >&2; exit 1; }

aab_file="countscore-$version_full.aab"
mkdir -p "$dir/store_listing" "$dir/screenshots"
cp "$AAB" "$dir/$aab_file"
cp -r "$ROOT/store_listing/en-US" "$ROOT/store_listing/fr-FR" "$dir/store_listing/"
cp -r "$ROOT/store_listing/assets/screenshots/phone" "$dir/screenshots/"
cp "$ROOT/store_listing/assets/feature_graphic.png" "$dir/"
cp "$ROOT/PLAY_STORE_DATA_SAFETY.md" "$ROOT/PUBLISHING.md" "$dir/"

if [[ "$track" == production ]]; then
  rollout_instruction="Set the staged rollout percentage to **$rollout %** (Déploiement progressif)."
else
  rollout_instruction="No rollout percentage on this track — skip."
fi

VERSION="$version" VERSION_CODE="$code" DATE="$(date +%F)" AAB_FILE="$aab_file" \
HANDOFF_DIR_WINDOWS="$dir_win" UPLOAD_SHA256="$sha" TRACK="$track_label" TRACK_MENU="$track_menu" \
ROLLOUT_PERCENT="$rollout" ROLLOUT_INSTRUCTION="$rollout_instruction" OPTIONAL_TASKS="$optional" \
RELEASE_NOTES_BLOCK="${notes_block%$'\n'}" \
python3 - "$SKILL/references/play-console-handoff.md" "$dir/HANDOFF.md" <<'PY'
import os, re, sys
text = open(sys.argv[1], encoding="utf-8").read()
text = re.sub(r"\{\{([A-Z0-9_]+)\}\}", lambda m: os.environ[m.group(1)], text)
open(sys.argv[2], "w", encoding="utf-8").write(text)
PY

if grep -n '{{' "$dir/HANDOFF.md"; then echo "unfilled placeholder in HANDOFF.md" >&2; exit 1; fi

cat <<EOF

Staged: $dir_win
  $aab_file, HANDOFF.md, store_listing/, screenshots/phone/, feature_graphic.png, PLAY_STORE_DATA_SAFETY.md, PUBLISHING.md

Cowork:           grant the folder above, then say: "Read HANDOFF.md in this folder and carry it out."
Claude in Chrome: open https://play.google.com/console signed in to the developer account, paste the
                  whole of HANDOFF.md into the side panel, and add: "The files it names are in $dir_win".
                  (The extension reads local files only with "Allow access to file URLs" enabled;
                  pasting avoids depending on it. The bundle upload still needs that folder.)
EOF
