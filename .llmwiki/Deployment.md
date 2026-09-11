# Deployment

> Scope: production topology and environment. For the procedure, use the `backend-deploy` skill.
> Related: [[Backend]] · [[Security]] · [[Web]] · [[LlmProviders]]
> Updated: 2026-09-11

## Facts

**URL**: whatever `PUBLIC_URL` in `backend/scripts/deploy.env` names. That file is
untracked, and so are the NAS hostname, the registry address and the SSH alias: the
repository is public and they are one person's infrastructure. The tracked template is
`backend/scripts/deploy.env.example`; `deploy_nas.sh` sources the real one and exits naming
any variable it is missing.

**TLS**: Synology **Web Station** with its built-in Let's Encrypt certificate, reverse
proxying to `http://127.0.0.1:8087`. Caddy was removed and is no longer part of the stack.

### Services — `backend/docker-compose.prod.yml`

| Service | Detail |
|---|---|
| `api` | FastAPI/uvicorn, **1 worker**. Image from the local NAS registry, `$REGISTRY/countscore:latest`. Port `127.0.0.1:8087:8000`. |
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

Verify with `curl "$PUBLIC_URL/health"` → `{"status": "ok", "version": …, "llm":
{"provider": …, "model": …, "credentials": …}}`. The `llm` block reports the model the
container actually resolved, which is the check that would have caught the 2026-09-09
outage — see [[LlmProviders]].

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
| `MISTRAL_API_KEY` / `MISTRAL_MODEL` / `MISTRAL_BASE_URL` | Mistral | — / `mistral-medium-latest` / — |
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
  and the NAS is on the LAN — pushing to a registry on that LAN avoids credentials, egress
  and a third-party dependency in the deploy path.
- **The deployment target left the repository (2026-09-11).** It was spread over
  `deploy_nas.sh`, `docker-compose.prod.yml`, `backend/README.md`, this page and the
  `backend-deploy` skill. Once the app's backend URL became a user setting, publishing the
  owner's NAS hostname and LAN registry IP alongside it served nothing. They moved to the
  untracked `backend/scripts/deploy.env`. Git history still carries them — rewriting it is
  forbidden by `CLAUDE.md`, and the point is that nothing published *from here on* does.
- **Backups are `pg_dump` on a cron sidecar with 7-day rotation**, not a managed service.
  The dataset is small and the recovery story is "copy a file back".
- **`LLM_PROVIDER` defaults to `bedrock` in code**, but production has been run on
  `mistral`; `backend/README.md` describes only the default. Check the actual `.env` on the
  NAS before assuming which provider answered a given request. **This bit (2026-09-09 →
  2026-09-11):** production set `LLM_PROVIDER=mistral` but not `MISTRAL_MODEL`, inherited the
  code default `mistral-large-latest` — a model the account's tier no longer allows — and
  every analysis 502'd for two days while `/health` still said `ok`. Closed on 2026-09-11 by
  three changes together: the default is now `mistral-medium-latest`, `/health` reports the
  resolved model, and production sets `MISTRAL_MODEL` explicitly. See `DONE.md` and
  [[LlmProviders]]. **Confirmed by the deploy (2026-09-11):** production picked up
  `mistral-medium-latest` from the *compose* default alone — the NAS `.env` was never edited —
  which proves the compose copy, not `app/config.py`, is the one production reads.
- **The compose file carries its own defaults, and they win.** `docker-compose.prod.yml`
  interpolates `${MISTRAL_MODEL:-…}` from the NAS `.env`, so a default written only in
  `app/config.py` never reaches production. Every provider default therefore exists twice and
  the two must move together — that duplication is what made the 2026-09-09 fix a five-file
  change rather than a one-line one.
