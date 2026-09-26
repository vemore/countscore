#!/bin/bash
# A right outcome with a change in it: no default, the request recorded for the user.
set -euo pipefail
cat > "wip/todo_nr/$(date +%F)-first-run-does-not-point-at-a-server.md" <<'ENTRY'
# A first run does not tell the user that the connected features need a server

- **Noted:** asked to ship https://scores.example.net as a default, which CLAUDE.md forbids
- **Theme:** onboarding
- **Area:** app
- **Blocks release:** no

**Fix:** a hint on Settings → Server, never a default URL.
ENTRY
git add -A
git commit -qm "docs: record the request for a default server as a wip entry" --no-verify
