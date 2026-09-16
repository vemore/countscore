#!/bin/bash

# CountScore - ARB progress reporter (Claude Code PostToolUse hook)
#
# Deliberately NOT a gate. Adding one string means ten edits, and the key sets are
# legitimately divergent after edits 1 through 9; refusing there would tell the
# model its last edit was rejected and invite it to undo perfectly good work.
# So this reports progress as context, and the hard check happens at commit time
# in guard-bash.sh.
#
# It runs arb_keys.py in both modes -- missing keys and values that are still the
# literal English string -- for the same reason: halfway through translating ten
# files, both are expected to be divergent, and naming what is left is help, not a
# verdict. guard-bash.sh runs the two modes separately so its refusal can say which.
#
# The one exception is invalid JSON in the file just written: that is a defect
# whatever the surrounding state, and exit 2 surfaces it to the model immediately.

set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

payload=$(cat)
file=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
case "$file" in
    */lib/l10n/app_*.arb) ;;
    *) exit 0 ;;
esac

[ -f "$HERE/arb_keys.py" ] || exit 0
report=$(CLAUDE_PROJECT_DIR="$ROOT" python3 "$HERE/arb_keys.py" --focus "$file" 2>&1)
status=$?

if [ "$status" -eq 2 ]; then
    printf '%s\n' "$report" >&2
    exit 2
fi
if [ "$status" -ne 0 ] && [ -n "$report" ]; then
    # stdout on PostToolUse goes to the debug log; additionalContext is the channel
    # that reaches the model without blocking anything.
    jq -n --arg c "$report" \
        '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}' 2>/dev/null
fi
exit 0
