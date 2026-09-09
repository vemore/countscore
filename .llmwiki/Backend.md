# Backend

> Scope: the FastAPI service — stack, layout, configuration, auth.
> Related: [[Api]] · [[Sync]] · [[LlmProviders]] · [[Deployment]] · [[Security]] · [[Testing]]
> Updated: 2026-09-09

## Facts

Lives in `backend/`. Package `countscore-backend` 0.1.0, setuptools backend, `uv.lock`
present. `backend/README.md` is the fullest existing prose doc.

### Stack

- **Python** `>=3.11` (`requires-python`), ruff `target-version = "py311"`, Docker image
  `python:3.13-slim`.
- fastapi >=0.141.1 · uvicorn[standard] · sqlmodel >=0.0.42 · asyncpg · psycopg2-binary ·
  alembic · pydantic v2 · pydantic-settings · `anthropic>=1.4,<2` · boto3 ·
  `openai>=2,<3` · argon2-cffi · httpx · python-multipart.
- Dev extras: pytest >=9.1.1 · pytest-asyncio · pytest-cov · ruff >=0.16.6 · mypy >=2.3.1 ·
  httpx · aiosqlite. Dependency group `dev` adds httpx-ws and testcontainers[postgres].
- No `requirements.txt`, no Makefile, no justfile.

### Layout

| Path | Role |
|---|---|
| `app/main.py` | `create_app()` factory + module-level `app`. CORS from settings, a `limit_body_size` middleware (413 above `max_body_bytes`), `lifespan` sets logging, includes the three routers, defines `GET /health`. |
| `app/config.py` | pydantic-settings `Settings` + `@lru_cache get_settings()`. |
| `app/db.py` | Async engine, `AsyncSessionLocal`, `get_session()` dependency. Skips `pool_size`/`max_overflow` when the URL contains `sqlite`. |
| `app/auth.py` | argon2 device tokens: `hash_token`, `verify_token`, `generate_token`, `AuthContext`, and the `require_device` dependency reading `Authorization: Bearer`. |
| `app/models/` | SQLModel tables: `group`, `device`, `player`, `game` (game_types, games, game_players, rounds, scores), `change_log`, `comment`, `rate_limit`. |
| `app/schemas/` | Pydantic DTOs: `groups`, `sync`, `comments`. |
| `app/routes/` | `groups`, `sync`, `comments` — see [[Api]]. |
| `app/services/` | `zapzap_prompt`, `prompt_builder`, `anthropic_client`, `budget`, `rate_limiter`, `ip_rate_limiter`, `notify`, and the `llm/` package — see [[LlmProviders]]. |
| `alembic/` | `env.py` (SQLModel metadata, reads `DATABASE_URL`/`ALEMBIC_DATABASE_URL`, strips `+asyncpg`) and a single revision `versions/0001_initial.py`. |

### Database

PostgreSQL 17 (`postgres:17-alpine`), asyncpg at runtime, sync psycopg for migrations,
in-memory SQLite (aiosqlite) for tests. Postgres-specific features in use: JSONB on
`change_log.payload`, and `pg_notify`/LISTEN in `app/services/notify.py`.

```bash
export DATABASE_URL=postgresql://...
alembic upgrade head                              # apply
alembic revision --autogenerate -m "add x"        # create
```

Autogenerate works because `alembic/env.py` imports `app.models` and uses
`SQLModel.metadata`.

### Auth

A device bearer token: a raw uuid4 hex issued at group create or join, stored argon2-hashed.
`require_device` guards everything except create, join, and the two stateless comment
endpoints. Revoked devices are refused.

### Configuration

`Settings` reads `.env` with `extra="ignore"`. Full env-var list in [[Deployment]].
`cors_origins` has a validator that **rejects `*` at startup**; `cors_origins_list` splits
on commas.

## Decisions & History

- **`mypy` is a declared dev dependency with no configuration anywhere** — no `[tool.mypy]`,
  no `mypy.ini`, no `setup.cfg`. A `.mypy_cache` exists, so it has been run ad hoc. Treat
  type checking as not part of the gate until someone configures it.
- **Ruff config is deliberately narrow**: line-length 100, select `E,F,I,B,UP,N,SIM,RUF`,
  ignore `B008` (FastAPI's `Depends()` in defaults is idiomatic) and `N805`. Per-file
  ignore on `app/services/zapzap_prompt.py` for `E501` and `RUF001`, because the prompt is
  verbatim French prose with typographic characters and must not be reflowed.
- **SQLite is the test database, Postgres the real one.** It keeps the unit suite fast and
  Docker-free; the cost is that the JSONB and LISTEN/NOTIFY paths need a real Postgres,
  which is why `test_sync_ws_integration.py` exists behind an `integration` marker.
