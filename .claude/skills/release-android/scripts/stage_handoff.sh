#!/usr/bin/env bash
# Stage a Play Console brief for the tasks the Publishing API cannot do, where a browser agent
# can reach it.
#
#   .claude/skills/release-android/scripts/stage_handoff.sh [tasks]
#
#   tasks   free text for Part B of the brief, e.g. "content rating, Data safety review";
#           default "none" (the read-only survey only)
#
# The bundle, the release notes, the listing and the graphics go through play_publish.py, not
# through this brief. Cowork and Claude in Chrome run on the Windows side of this WSL machine,
# and their file access only sees folders the user grants — so the brief goes to the Windows
# Downloads folder, never to a path inside WSL.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
SKILL="$ROOT/.claude/skills/release-android"
tasks="${1:-none}"

version_full="$(sed -n 's/^version: *//p' "$ROOT/pubspec.yaml")"

win_user="$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r')"
[[ -n "$win_user" && -d "/mnt/c/Users/$win_user" ]] || { echo "cannot resolve the Windows user folder" >&2; exit 1; }
dir="/mnt/c/Users/$win_user/Downloads/countscore-console-$version_full"
dir_win="C:\\Users\\$win_user\\Downloads\\countscore-console-$version_full"
[[ ! -e "$dir" ]] || { echo "$dir already exists — remove it first" >&2; exit 1; }

mkdir -p "$dir"
cp "$ROOT/PLAY_STORE_DATA_SAFETY.md" "$ROOT/PUBLISHING.md" "$dir/"

VERSION="$version_full" DATE="$(date +%F)" TASKS="$tasks" \
python3 - "$SKILL/references/play-console-handoff.md" "$dir/HANDOFF.md" <<'PY'
import os, re, sys
text = open(sys.argv[1], encoding="utf-8").read()
text = re.sub(r"\{\{([A-Z0-9_]+)\}\}", lambda m: os.environ[m.group(1)], text)
open(sys.argv[2], "w", encoding="utf-8").write(text)
PY

if grep -n '{{' "$dir/HANDOFF.md"; then echo "unfilled placeholder in HANDOFF.md" >&2; exit 1; fi

cat <<EOF

Staged: $dir_win
  HANDOFF.md, PLAY_STORE_DATA_SAFETY.md, PUBLISHING.md

Cowork:           grant the folder above, then say: "Read HANDOFF.md in this folder and carry it out."
Claude in Chrome: open https://play.google.com/console signed in to the developer account, paste the
                  whole of HANDOFF.md into the side panel, and add: "The documents it names are in $dir_win".
EOF
