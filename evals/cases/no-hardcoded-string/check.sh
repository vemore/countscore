#!/bin/bash
# check.sh <worktree> [<base>]: see evals/lib.sh
. "$(dirname "$0")/../../lib.sh"
ev_init "$@"

# The literal must not be in any hand-written Dart file (generated localizations excepted).
lit=$(grep -rlis "board-game nights" "$WT/lib" --include='*.dart' | grep -v '/lib/l10n/app_localizations' || true)
if [ -z "$lit" ]; then ok "no hardcoded literal in lib/"
else fail "no hardcoded literal in lib/: ${lit#$WT/}"; fi

# Keys the template gained since the base.
new_keys=$(python3 - "$WT" "$BASE" <<'PY'
import json, subprocess, sys
wt, base = sys.argv[1], sys.argv[2]
old = json.loads(subprocess.run(["git", "-C", wt, "show", f"{base}:lib/l10n/app_fr.arb"],
                                capture_output=True, text=True, check=True).stdout)
new = json.load(open(f"{wt}/lib/l10n/app_fr.arb"))
print(" ".join(sorted(k for k in new if not k.startswith("@") and k not in old)))
PY
)
if [ -n "$new_keys" ]; then ok "the template gained a key: $new_keys"
else fail "the template (app_fr.arb) gained a key"; fi

used=""
for k in $new_keys; do grep -q "\.$k\b" "$WT/lib/screens/about_screen.dart" && used="$k"; done
if [ -n "$used" ]; then ok "about_screen.dart reads it through AppLocalizations ($used)"
else fail "about_screen.dart reads a new key through AppLocalizations"; fi
if [ -n "$used" ] && grep -q "\b$used\b" "$WT/lib/l10n/app_localizations.dart"; then
    ok "localizations regenerated (flutter gen-l10n)"
else fail "localizations regenerated (flutter gen-l10n)"; fi

arb="$WT/.claude/hooks/arb_keys.py"
assert "arb_keys.py --keys: ten ARB files hold the same keys" env CLAUDE_PROJECT_DIR="$WT" python3 "$arb" --keys
assert "arb_keys.py --values: no value left in English" env CLAUDE_PROJECT_DIR="$WT" python3 "$arb" --values
assert_committed
ev_done
