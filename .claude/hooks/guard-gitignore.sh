#!/bin/bash

# CountScore - .gitignore guard (Claude Code PostToolUse hook)
#
# web/sqlite3.wasm and web/drift_worker.js are tracked on purpose. This asks git
# itself whether a rule now ignores them, rather than looking for their names in
# the text: "*.wasm", "web/*" or a cancelled negation all ignore them without
# naming either file.
#
# --no-index is mandatory. Both files are tracked, and without it check-ignore
# consults the index and always answers "not ignored" -- the check would be inert.
#
# Gitignoring a tracked file does not untrack it, so PostToolUse is not too late.

set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

payload=$(cat)
file=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
case "$file" in
    *.gitignore|*/.gitignore) ;;
    *) exit 0 ;;
esac

cd "$ROOT" 2>/dev/null || exit 0
if git check-ignore -q --no-index web/sqlite3.wasm 2>/dev/null || git check-ignore -q --no-index web/drift_worker.js 2>/dev/null; then
    cat >&2 <<MSG
That .gitignore edit now ignores a file that is tracked on purpose:

$(git check-ignore -v --no-index web/sqlite3.wasm web/drift_worker.js 2>/dev/null)

web/sqlite3.wasm (744 KB) and web/drift_worker.js (355 KB) are committed so a fresh
clone can run the PWA without fetching binaries. Revert that rule. See .llmwiki/Web.md.
MSG
    exit 2
fi
exit 0
