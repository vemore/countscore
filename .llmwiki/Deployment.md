# Deployment

> Scope: production topology and environment. For the procedure, use the `backend-deploy` skill.
> Related: [[Backend]] · [[Security]] · [[Web]] · [[LlmProviders]]
> Updated: 2026-09-09

## Facts

**URL**: `https://countscore.ombivince.synology.me`

**TLS**: Synology **Web Station** with its built-in Let's Encrypt certificate, reverse
proxying to `http://127.0.0.1:8087`. Caddy was removed and is no longer part of the stack.

### Services — `backend/docker-compose.prod.yml`

| Service | Detail |
|---|---|
| `api` | FastAPI/uvicorn, **1 worker**. Image from the local NAS registry `192.168.1.25:5050/countscore:latest`. Port `127.0.0.1:8087:8000`. |
| `db` | Postgres 17-alpine, mounted volume. |
| `db-backup` | Sidecar cron: `pg_dump → /backups`, 7-day rotation. |

The single worker is **not** a resource decision: `ip_rate_limiter.py` holds its state in
process memory, so more than one worker would silently multiply the effective rate limit.
The local `docker-compose.yml` and the Dockerfile default to 2 workers, which is fine for
dev. See [[LlmProviders]].

```bash
cd backend
./scripts/deploy_nas.sh                    # build → push registry → up → alembic upgrade
./scripts/deploy_nas.sh --rollback <sha>   # roll back to a git sha
```

Dev uses `docker-compose.yml` (no TLS, local Postgres): `docker compose up -d` — db plus
api on 8000 plus the backup sidecar.

Verify with `https://countscore.ombivince.synology.me/health` → `{"status": "ok"}`.

There is **no deployment path for the Flutter web app** in this repo — no vhost, no
hosting config. Only the backend container is covered. See [[Web]].

### Environment variables

`.env` is never committed (`.gitignore`); `backend/.env.example` is the template.

| Variable | Meaning | Default |
|---|---|---|
| `DATABASE_URL` | Postgres DSN (`postgresql+asyncpg://…` at runtime) | required |
| `POSTGRES_PASSWORD` / `POSTGRES_USER` / `POSTGRES_DB` | Compose database | required / `countscore` / `countscore` |
| `ANTHROPIC_API_KEY` | Claude comments | required for `/comments` |
| `COMMENT_MODEL` | Claude model | `claude-haiku-4-5` |
| `COMMENT_MEMORY_SIZE` | Comments kept in the sliding memory | `5` |
| `DEFAULT_BUDGET_CENTS` | Monthly budget per group | `100` |
| `LLM_PROVIDER` | ZapZap provider: `bedrock` \| `gemini` \| `mistral` | `bedrock` |
| `BEDROCK_MODEL_ID` | Bedrock model | `us.meta.llama3-3-70b-instruct-v1:0` |
| `AWS_REGION` / `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_SESSION_TOKEN` | Bedrock credentials | required if bedrock |
| `GEMINI_API_KEY` / `GEMINI_MODEL` / `GEMINI_BASE_URL` | Gemini | — / `gemini-2.5-pro` / — |
| `MISTRAL_API_KEY` / `MISTRAL_MODEL` / `MISTRAL_BASE_URL` | Mistral | — / `mistral-large-latest` / — |
| `CORS_ORIGINS` | Allowed origins, CSV. `*` is rejected at startup | prod URL |
| `RL_PER_MINUTE` / `RL_PER_HOUR` / `RL_PER_DAY` | Per-device rate limit | `6` / `30` / `100` |
| `IP_RL_PER_MINUTE` / `IP_RL_PER_HOUR` | Anonymous IP rate limit on the LLM endpoints | `5` / `30` |
| `GROUP_RL_PER_MINUTE` / `GROUP_RL_PER_HOUR` | IP rate limit on group create/join, own bucket | `3` / `10` |
| `HSTS_ENABLED` | Send `Strict-Transport-Security`. `true` in prod, `false` for local http | `false` |
| `MAX_BODY_BYTES` | Request body cap (413 above) | `262144` |
| `LOG_LEVEL` | | — |

## Decisions & History

- **Web Station replaced Caddy.** The NAS already terminates TLS with integrated Let's
  Encrypt; running Caddy meant a second certificate authority path and another container to
  keep alive for no gain.
- **A local Docker registry on the NAS rather than a public one.** The image is not public
  and the NAS is on the LAN — pushing to `192.168.1.25:5050` avoids credentials, egress and
  a third-party dependency in the deploy path.
- **Backups are `pg_dump` on a cron sidecar with 7-day rotation**, not a managed service.
  The dataset is small and the recovery story is "copy a file back".
- **`LLM_PROVIDER` defaults to `bedrock` in code**, but production has been run on
  `mistral`; `backend/README.md` describes only the default. Check the actual `.env` on the
  NAS before assuming which provider answered a given request. **This bit (2026-09-09):**
  production sets `LLM_PROVIDER=mistral` but not `MISTRAL_MODEL`, so it inherits the code
  default `mistral-large-latest` — a model the account's tier no longer allows. Every
  analysis 502s and `/health` still says `ok`. See `TODO.md` and [[LlmProviders]].
