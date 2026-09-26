# The db-migration skill puts every schema step in the sync layer, which raises its lane

**Status:** done (2026-09-26) — closed by refactor/schema-steps-out-of-sync. Every shared step,
`applyV12` to `applyV21` with `applyV20` from the deleted `lib/services/drift/schema_v20.dart`,
moved verbatim to `lib/services/schema_steps.dart`; `sync_schema.dart` keeps `applySyncV10` and
the v11 triggers, and the db-migration skill names the new file.

- **Noted:** 2026-09-24 — while writing schema v20 on fix/game-ends-on-last-player
- **Theme:** tooling
- **Area:** tooling
- **Blocks release:** no

`.claude/skills/db-migration/SKILL.md` says to write each shared migration step "once, in
`lib/services/sync/sync_schema.dart`". The ship-parallel briefing treats any change under
`lib/services/sync/` as lane C. So a data-only step with nothing to do with sync (v20 sets a
game-over condition) either raises its pull request to lane C or goes elsewhere. v20 went to
`lib/services/drift/schema_v20.dart`, imported by both `DatabaseService._upgradeDB` and
`AppDatabase.onUpgrade`, which splits the chain across two files.

**Fix:** move the schema steps (v12 onward, and v20) out of `sync_schema.dart` into one
engine-neutral file (for instance `lib/services/schema_steps.dart`), keep only the sync
bookkeeping (v10, v11 triggers) in `sync_schema.dart`, and point the skill at the new file.
Or, if the lane rule is the wrong half, say in the skill and in [[ParallelDelivery]] that
`sync_schema.dart` does not by itself mean lane C.

**Acceptance:**
- The db-migration skill names one file for a new shared step, and that file is not under
  `lib/services/sync/`, or [[ParallelDelivery]] exempts `sync_schema.dart` from lane C.
- Every `applyVN` lives in the file the skill names.
