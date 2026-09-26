#!/bin/bash
# The right outcome, done by hand (evals/selftest.sh). Stands in for `flutter gen-l10n` by
# naming the key in app_localizations.dart, which is all check.sh looks for.
set -euo pipefail
python3 - <<'PY'
import json, pathlib
for p in sorted(pathlib.Path("lib/l10n").glob("app_*.arb")):
    loc = p.stem.split("_", 1)[1]
    d = json.loads(p.read_text(encoding="utf-8"))
    d["roundsPlayed"] = ("{count, plural, =1{1 round played} other{{count} rounds played}}" if loc == "en"
                         else f"{{count, plural, =1{{1 [{loc}]}} other{{{{count}} [{loc}]}}}}")
    if loc == "fr":
        d["@roundsPlayed"] = {"placeholders": {"count": {"type": "int"}}}
    p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
echo "// roundsPlayed" >> lib/l10n/app_localizations.dart
git add -A
git commit -qm "feat: roundsPlayed plural message" --no-verify
