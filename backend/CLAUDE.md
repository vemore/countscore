# CountScore Backend — Instructions for Claude Code

FastAPI + Postgres service: group sharing, delta-log sync, and LLM-generated game
commentary. Python `>=3.11`.

## Read the wiki first

Background lives in the wiki at the repo root — load these before non-trivial work:

- `.llmwiki/Backend.md` — stack, module layout, settings, device-token auth
- `.llmwiki/Api.md` — every endpoint, its auth requirement, its failure modes
- `.llmwiki/Sync.md` — delta-log, per-field LWW, WebSocket signalling
- `.llmwiki/LlmProviders.md` — the two LLM paths, ZapZap prompt, rate limits
- `.llmwiki/Deployment.md` — NAS topology and the full environment-variable table
- `.llmwiki/Security.md` — defended surfaces and the open debt

Deploying is a skill: `backend-deploy`. Do not improvise the steps.

## Commands

```bash
# Setup
pip install -e ".[dev]"
cp .env.example .env          # then fill it in; .env is never committed

# Run
export DATABASE_URL=postgresql+asyncpg://countscore:...@localhost/countscore
uvicorn app.main:app --reload           # docs at /docs
docker compose up -d                    # or: db + api on :8000 + backup sidecar

# Test
pytest -m 'not integration' -q          # fast, no Docker
pytest -v                               # everything; `integration` needs Docker

# Lint
ruff check .
ruff format .

# Migrations
alembic upgrade head
alembic revision --autogenerate -m "add x"
```

## Rules

1. **Never commit `.env`.** `.env.example` is the template and must stay in sync with
   `app/config.py`.
2. **Production runs exactly one uvicorn worker.** `ip_rate_limiter.py` keeps state in
   process memory, so a second worker silently doubles the effective rate limit. Do not
   raise the worker count without moving that state out of memory first.
3. **Never let `CORS_ORIGINS` become `*`.** A validator rejects it at startup — leave it in.
4. **The ZapZap generation prompt must stay identical across bedrock, gemini and mistral.**
   It is the control variable that makes provider comparison meaningful.
   `app/services/zapzap_prompt.py` is exempt from `E501`/`RUF001` on purpose: it is
   verbatim French prose and must not be reflowed.
5. **No tool use in LLM calls.** That is a prompt-injection control, not a limitation.
6. **New entity?** Use the `db-migration` skill — the mobile and server schemas move
   together, and `ENTITY_HANDLERS` in the sync service is easy to forget.

## Gotchas

- **mypy is a declared dev dependency with no configuration anywhere.** There is no
  `[tool.mypy]`, no `mypy.ini`. Type checking is not part of the gate; do not report it as
  passing.
- Tests run on in-memory SQLite while production is Postgres. JSONB and `LISTEN/NOTIFY`
  paths are only covered by the `integration`-marked tests.
- Ruff: line length 100, `select = E,F,I,B,UP,N,SIM,RUF`, `ignore = B008,N805`.
- `openai` is pinned `>=2,<3` while 3.x is out — see `TODO.md`.
