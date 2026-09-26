#!/bin/bash
# check.sh <worktree> [<base>]: the script form of evals.json id 1 (see evals/lib.sh).
. "$(dirname "$0")/../../../../../evals/lib.sh"
ev_init "$@"

sv_sqflite() { sed -nE 's/.*static const schemaVersion = ([0-9]+);.*/\1/p' | head -1; }
sv_drift()   { sed -nE 's/.*int get schemaVersion => ([0-9]+);.*/\1/p' | head -1; }

old=$(g show "$BASE:lib/services/database_service.dart" | sv_sqflite)
new=$(sv_sqflite < "$WT/lib/services/database_service.dart")
drift=$(sv_drift < "$WT/lib/services/drift/database.dart")
want=$(( ${old:-0} + 1 ))

if [ "$new" = "$want" ]; then ok "DatabaseService.schemaVersion bumped $old -> $new"
else fail "DatabaseService.schemaVersion bumped by one ($old -> ${new:-?}, want $want)"; fi
if [ -n "$drift" ] && [ "$drift" = "$new" ]; then ok "AppDatabase.schemaVersion equals it ($drift)"
else fail "AppDatabase.schemaVersion equals it (${drift:-?} vs ${new:-?})"; fi

players=$(awk '/^class Players extends Table/,/^}/' "$WT/lib/services/drift/tables.dart")
if echo "$players" | grep -Eq 'TextColumn get notes\b.*nullable\(\)'; then ok "Players declares a nullable notes column"
else fail "Players declares a nullable notes column (TextColumn get notes ... nullable())"; fi

tests=$(added_files | grep -E '^test/.*\.dart$' || true)
covering=""
for t in $tests; do
    if grep -q "notes" "$WT/$t" && grep -Eq "$want\b" "$WT/$t"; then covering="$t"; fi
done
if [ -n "$covering" ]; then ok "a new test covers the migration: $covering"
else fail "a new test under test/ covers the migration to v$want (names notes and $want)"; fi
assert_committed
ev_done
