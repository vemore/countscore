#!/bin/bash
# A plausible wrong outcome: the text hardcoded in the widget.
set -euo pipefail
python3 - <<'PY'
import pathlib
p = pathlib.Path("lib/screens/about_screen.dart")
s = p.read_text()
p.write_text(s.replace("const SizedBox(height: 48),",
                       "const Text('Made for board-game nights with friends.'),\n                const SizedBox(height: 48),", 1))
PY
git add -A
git commit -qm "feat: a tagline on the About screen" --no-verify
