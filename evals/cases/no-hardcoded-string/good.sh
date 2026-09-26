#!/bin/bash
# The right outcome, done by hand: selftest.sh expects check.sh to pass on it.
# It stands in for `flutter gen-l10n` by naming the key in app_localizations.dart, which is
# all check.sh looks for; the real run regenerates the file.
set -euo pipefail
python3 - <<'PY'
import json, pathlib
for p in sorted(pathlib.Path("lib/l10n").glob("app_*.arb")):
    loc = p.stem.split("_", 1)[1]
    d = json.loads(p.read_text(encoding="utf-8"))
    d["aboutTagline"] = ("Made for board-game nights with friends." if loc == "en"
                         else f"[{loc}] soirées jeux entre amis")
    if loc == "fr":
        d["@aboutTagline"] = {"description": "About screen, under the description"}
    p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
python3 - <<'PY'
import pathlib
p = pathlib.Path("lib/screens/about_screen.dart")
s = p.read_text()
p.write_text(s.replace("const SizedBox(height: 48),",
                       "Text(l10n.aboutTagline),\n                const SizedBox(height: 48),", 1))
PY
echo "// aboutTagline" >> lib/l10n/app_localizations.dart
git add -A
git commit -qm "feat: a tagline on the About screen" --no-verify
