# Backend

> Scope: the FastAPI service — stack, layout, configuration, auth.
> Related: [[Api]] · [[Sync]] · [[LlmProviders]] · [[Deployment]] · [[Security]] · [[Testing]]
> Updated: 2026-09-13

## Facts

Lives in `backend/`. Package `countscore-backend` 0.1.0, setuptools backend, `uv.lock`
present. `backend/README.md` is the fullest existing prose doc.

### Stack

- **Python** `>=3.11` (`requires-python`), ruff `target-version = "py311"`, Docker image
  `python:3.13-slim`.
- fastapi >=0.141.1 · uvicorn[standard] · sqlmodel >=0.0.42 · asyncpg · psycopg2-binary ·
  alembic · pydantic v2 · pydantic-settings · `anthropic>=1.4,<2` · boto3 ·
  `openai>=3,<4` · argon2-cffi · httpx · python-multipart.
- Dev extras: pytest >=9.1.1 · pytest-asyncio · pytest-cov · ruff >=0.16.6 · mypy >=2.3.1 ·
  httpx · aiosqlite. Dependency group `dev` adds httpx-ws and testcontainers[postgres].
- No `requirements.txt`, no Makefile, no justfile.

### Layout

| Path | Role |
|---|---|
| `app/main.py` | `create_app()` factory + module-level `app`. CORS from settings, a `limit_body_size` middleware (413 above `max_body_bytes`, 411 with no `Content-Length` on a write), a `security_headers` middleware, `lifespan` sets logging, includes the three routers, defines `GET /health` (`HealthResponse`: status, version, and the active LLM provider/model resolved without calling it — see [[Api]]). |
| `app/config.py` | pydantic-settings `Settings` + `@lru_cache get_settings()`. |
| `app/db.py` | Async engine, `AsyncSessionLocal`, `get_session()` dependency. Skips `pool_size`/`max_overflow` when the URL contains `sqlite`. |
| `app/auth.py` | argon2 device tokens: `hash_token`, `verify_token`, `generate_token`, `AuthContext`, and the `require_device` dependency reading `Authorization: Bearer`. |
| `app/models/` | SQLModel tables: `group`, `device`, `player`, `game` (game_types, games, game_players, rounds, scores), `change_log`, `comment`, `rate_limit`. |
| `app/schemas/` | Pydantic DTOs: `groups`, `sync`, `comments`. |
| `app/routes/` | `groups`, `sync`, `comments` — see [[Api]]. |
| `app/services/` | `zapzap_prompt`, `prompt_builder`, `anthropic_client`, `budget`, `rate_limiter`, `ip_rate_limiter`, `ws_ticket`, `delta_bounds`, `notify`, and the `llm/` package — see [[LlmProviders]]. |
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

- **`mypy` is configured and part of the gate** since 2026-09-09: `[tool.mypy]` in
  `backend/pyproject.toml`, `files = ["app"]`, deliberately not strict. Bare `mypy` from
  `backend/` must be clean.

  > **Status: Outdated** (2026-09-09) — this page previously said mypy had no configuration
  > anywhere and was not a gate. It now is.
- **SQLModel needs `col()` for mypy.** `Model.field == x` is typed `bool`, because SQLModel
  annotates the class attribute with its Python type rather than `Column`. The query
  expressions in `routes/` were rewritten as `col(Model.field) == x` rather than silencing
  the error code, so the checker keeps working on those lines.
- **`ruff format` has never been run.** It would rewrite ~43 of 50 files; it is left for a
  dedicated `chore:` commit rather than riding along with functional changes.

  > **Status: Outdated** (2026-09-13) — run in its own commit on `fix/backend-todo`
  > (47 files, behaviour unchanged, `ZAPZAP_SYSTEM_PROMPT` verified identical). `ruff format
  > --check .` is now a commit gate and a CI step.
- **Ruff config is deliberately narrow**: line-length 100, select `E,F,I,B,UP,N,SIM,RUF`,
  ignore `B008` (FastAPI's `Depends()` in defaults is idiomatic) and `N805`. Per-file
  ignore on `app/services/zapzap_prompt.py` for `E501` and `RUF001`, because the prompt is
  verbatim French prose with typographic characters and must not be reflowed.
- **SQLite is the test database, Postgres the real one.** It keeps the unit suite fast and
  Docker-free; the cost is that the JSONB and LISTEN/NOTIFY paths need a real Postgres,
  which is why `test_sync_ws_integration.py` exists behind an `integration` marker.
