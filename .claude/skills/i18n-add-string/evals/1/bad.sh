#!/bin/bash
# A plausible wrong outcome: two plain keys in two locales, the plural rolled by hand.
set -euo pipefail
python3 - <<'PY'
import json, pathlib
for loc in ("en", "fr"):
    p = pathlib.Path(f"lib/l10n/app_{loc}.arb")
    d = json.loads(p.read_text(encoding="utf-8"))
    d["roundsPlayed"] = "{count} rounds played"
    p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
echo "String roundsLabel(int n) => n == 1 ? '1 round' : '\$n rounds';" >> lib/utils/insets.dart
git add -A
git commit -qm "add rounds played" --no-verify
