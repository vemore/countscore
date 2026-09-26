# Schema steps with sync effects sit outside the paths that make a change lane C

- **Noted:** 2026-09-26 — independent review of refactor/schema-steps-out-of-sync (#230)
- **Theme:** deploy-safety
- **Area:** tooling
- **Blocks release:** no

The ship-parallel lane rule treats a change under `lib/services/sync/` as lane C. Since #230,
every shared schema step lives in `lib/services/schema_steps.dart`, outside that path, yet
several of them act on sync:

- `applyV20` updates `game_types`, which fires the v11 capture trigger and pushes linked rows.
- `applyV21` raises `sync_flags.suppress` around its back-fill so it is *not* pushed.
- `defaultRulesSlugs` and `keypadShortcutSeeds` are read by `sync_store.dart` at pull time.

A future step that gets the suppress flag or the capture wrong corrupts every device in a
group, and today it would ship in lane A or B.

**Fix:** make the lane rule follow what the SQL does, not where the file is: a change that
touches `sync_flags`, a `trg_sync_*` trigger, the outbox, or a helper `sync_store.dart`
imports from `schema_steps.dart` is lane C wherever it lives. State it in
[[ParallelDelivery]] and the ship-parallel briefing (once the PRs editing them have merged).

**Acceptance:**
- [[ParallelDelivery]] and ship-parallel name the sync-effect criterion above for lane C.
- A new step in `schema_steps.dart` that writes `sync_flags` or fires a capture trigger is
  classified lane C by the briefing's rule; a data-only step on a table without a capture
  trigger is not.
- The db-migration skill says which of its steps raise the lane, and why.
