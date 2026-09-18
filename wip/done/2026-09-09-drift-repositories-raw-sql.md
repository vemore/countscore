# The Drift repositories are raw SQL

**Status:** dropped (2026-09-18) — chore/refine-2026-09-18. Internal quality with no user-visible gain: 63 raw-SQL calls, much of it shared with `sync_schema`, make the conversion cost more than it returns.

- **Noted:** 2026-09-09 — surfaced during the LLM-wiki migration
- **Theme:** drift-typed-queries
- **Area:** app
- **Blocks release:** no

`drift_repositories.dart` uses `customSelect` / `customInsert` throughout, a faithful port of
the sqflite queries — right for a safe migration, but the type-safe-query benefit of Drift is
still unbanked. Convert the simplest repositories first to prove the pattern.
