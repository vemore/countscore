#!/bin/bash
# The shape of the right outcome, by hand (evals/selftest.sh): enough for check.sh, not a
# compiling migration.
set -euo pipefail
old=$(sed -nE 's/.*static const schemaVersion = ([0-9]+);.*/\1/p' lib/services/database_service.dart | head -1)
new=$((old + 1))
sed -i -E "s/static const schemaVersion = $old;/static const schemaVersion = $new;/" lib/services/database_service.dart
sed -i -E "s/int get schemaVersion => $old;/int get schemaVersion => $new;/" lib/services/drift/database.dart
python3 - <<'PY'
import pathlib, re
p = pathlib.Path("lib/services/drift/tables.dart")
s = p.read_text()
s = re.sub(r"(class Players extends Table \{\n)", r"\1  TextColumn get notes => text().nullable()();\n", s, count=1)
p.write_text(s)
PY
cat > "test/migration_v${old}_to_v${new}_test.dart" <<DART
// applyV$new adds players.notes.
void main() {}
DART
git add -A
git commit -qm "feat: players.notes (schema v$new)" --no-verify
