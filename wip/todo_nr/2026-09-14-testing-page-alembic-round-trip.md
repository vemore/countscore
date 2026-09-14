# Testing.md still describes the backend job's Alembic step as upgrade + check

- **Noted:** 2026-09-14 — while building chore/merge-safety
- **Theme:** docs
- **Area:** docs
- **Blocks release:** no

chore/merge-safety changed the `backend` CI job's Alembic step to `upgrade head`,
`downgrade base`, `upgrade head`, `check` (`.github/workflows/ci.yml`). The jobs table in
`.llmwiki/Testing.md` (the `backend` row, "`alembic upgrade head` + `alembic check`") still
names the old step. That page was owned by the parallel fix/hooks-gates pull request, so it
was left alone to avoid a conflict.

**Fix:** once both have merged, change that row to the round trip and bump `Updated:`.
