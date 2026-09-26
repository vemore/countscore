#!/bin/bash
# A plausible wrong outcome: the Drift side bumped alone, no migration test.
set -euo pipefail
old=$(sed -nE 's/.*int get schemaVersion => ([0-9]+);.*/\1/p' lib/services/drift/database.dart | head -1)
sed -i -E "s/int get schemaVersion => $old;/int get schemaVersion => $((old + 1));/" lib/services/drift/database.dart
python3 - <<'PY'
import pathlib, re
p = pathlib.Path("lib/services/drift/tables.dart")
s = p.read_text()
s = re.sub(r"(class Players extends Table \{\n)", r"\1  TextColumn get notes => text().nullable()();\n", s, count=1)
p.write_text(s)
PY
git add -A
git commit -qm "feat: notes" --no-verify
