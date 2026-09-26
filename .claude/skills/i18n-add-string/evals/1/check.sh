#!/bin/bash
# check.sh <worktree> [<base>]: the script form of evals.json id 1 (see evals/lib.sh).
. "$(dirname "$0")/../../../../../evals/lib.sh"
ev_init "$@"

report=$(python3 - "$WT" <<'PY'
import json, pathlib, re, sys
wt = pathlib.Path(sys.argv[1])
files = sorted((wt / "lib/l10n").glob("app_*.arb"))
missing, not_plural = [], []
for p in files:
    d = json.loads(p.read_text(encoding="utf-8"))
    v = d.get("roundsPlayed")
    if v is None:
        missing.append(p.stem)
    elif not re.search(r"\{\s*\w+\s*,\s*plural\s*,", v):
        not_plural.append(p.stem)
meta = json.loads((wt / "lib/l10n/app_fr.arb").read_text(encoding="utf-8")).get("@roundsPlayed", {})
ph = meta.get("placeholders", {})
int_ph = any(isinstance(x, dict) and x.get("type") in ("int", "num") for x in ph.values())
print(f"{len(files)}|{' '.join(missing)}|{' '.join(not_plural)}|{int(int_ph)}")
PY
)
IFS='|' read -r nfiles missing notplural intph <<< "$report"
if [ "$nfiles" = 10 ] && [ -z "$missing" ]; then ok "roundsPlayed in all ten ARB files"
else fail "roundsPlayed in all ten ARB files (missing: ${missing:-none}, files: $nfiles)"; fi
if [ -z "$missing" ] && [ -z "$notplural" ]; then ok "every value is an ICU plural"
else fail "every value is an ICU plural (not: ${notplural:-n/a})"; fi
if [ "$intph" = 1 ]; then ok "@roundsPlayed in the template with an int placeholder"
else fail "@roundsPlayed in the template with an int placeholder"; fi

arb="$WT/.claude/hooks/arb_keys.py"
assert "arb_keys.py --keys" env CLAUDE_PROJECT_DIR="$WT" python3 "$arb" --keys
assert "arb_keys.py --values" env CLAUDE_PROJECT_DIR="$WT" python3 "$arb" --values
assert "app_localizations.dart declares roundsPlayed" grep -q "roundsPlayed" "$WT/lib/l10n/app_localizations.dart"

handrolled=$(g diff "$BASE" -- 'lib/*.dart' ':!lib/l10n/app_localizations*.dart' | grep -E '^\+' | grep -E '==\s*1\s*\?' || true)
if [ -z "$handrolled" ]; then ok "no hand-rolled plural added"
else fail "no hand-rolled plural added: $(echo "$handrolled" | head -1)"; fi
assert_committed
ev_done
