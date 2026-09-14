# `alembic check` reports drift that predates the sync contract

- **Noted:** 2026-09-13 — while validating `0002_sync_contract` on Postgres
- **Theme:** backend-hardening
- **Area:** backend
- **Blocks release:** no

After `alembic upgrade head` on Postgres 17, `alembic check` reports four type differences:
`change_log.id`, `.client_lamport`, `.server_seq` are `BIGINT` in
`alembic/versions/0001_initial.py` but `int` in `app/models/change_log.py`; `comments.content`
is `TEXT` in the DDL but `AutoString` in `app/models/comment.py`. Nothing is lost today, but
`--autogenerate` will propose narrowing them, and the tests run on the narrower types.

**Fix:** explicit `sa_column` on those four fields matching the DDL, then `alembic check` as a
CI step on a Postgres job.
