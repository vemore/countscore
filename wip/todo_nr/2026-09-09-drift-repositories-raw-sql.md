# The Drift repositories are raw SQL

- **Noted:** 2026-09-09 — surfaced during the LLM-wiki migration
- **Theme:** drift-typed-queries
- **Area:** app
- **Blocks release:** no

`drift_repositories.dart` uses `customSelect` / `customInsert` throughout, a faithful port of
the sqflite queries — right for a safe migration, but the type-safe-query benefit of Drift is
still unbanked. Convert the simplest repositories first to prove the pattern.
