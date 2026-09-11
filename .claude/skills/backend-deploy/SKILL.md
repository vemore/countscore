---
name: backend-deploy
description: Deploy or roll back the CountScore FastAPI backend on the Synology NAS — build, push to the local registry, restart the container, run Alembic migrations, verify health. Use when shipping backend changes to production, rolling back a bad deploy, changing production environment variables, or diagnosing the live service. Triggers: "deploy the backend", "déployer le backend", "push to prod", "rollback", "deploy_nas", "alembic upgrade in prod", "restart the api container".
---

# Deploying the CountScore backend

Target: the host named by `PUBLIC_URL` in `backend/scripts/deploy.env` — untracked, because
it is one person's infrastructure and this repository is public. Copy
`backend/scripts/deploy.env.example` if it is missing. Topology, service list and the full
environment table are in `.llmwiki/Deployment.md`. For general NAS operations unrelated to
this app, the `deploy-nas` skill covers the machine itself.

## Topology in one line

Synology **Web Station** terminates TLS (integrated Let's Encrypt) and reverse-proxies to
`http://127.0.0.1:8087` → the `api` container (uvicorn, **1 worker**), alongside
`db` (Postgres 17-alpine) and a `db-backup` sidecar doing a daily `pg_dump` with 7-day
rotation. Caddy is no longer used.

## The one rule you cannot break

**Production runs exactly one uvicorn worker.** `app/services/ip_rate_limiter.py` holds
its state in process memory, so a second worker silently doubles the effective anonymous
rate limit on the unauthenticated `/comments` endpoints. Do not raise `--workers` in
`docker-compose.prod.yml` without first moving that state to Postgres or Redis.

## 1. Pre-flight

```bash
cd backend
ruff check .
pytest -m 'not integration' -q
pytest -v                          # if Docker is available; covers WS + LISTEN/NOTIFY
```

If the change touches the schema, confirm an Alembic revision exists and **read it** —
autogenerate reads renames as drop-plus-add, which loses data:

```bash
ls alembic/versions/
```

## 2. Environment

`.env` is never committed. On a first deploy, or when a new setting appears in
`app/config.py`:

```bash
cp .env.example .env      # then fill it in
```

Required: `DATABASE_URL`, `POSTGRES_PASSWORD`, `ANTHROPIC_API_KEY`, and the credentials for
whichever `LLM_PROVIDER` is selected (`AWS_*` for bedrock, `GEMINI_API_KEY`,
`MISTRAL_API_KEY`). `CORS_ORIGINS` must list the real PWA origin — a validator rejects `*`
at startup, so a wrong value fails fast rather than opening the API.

Keep `.env.example` in sync with `app/config.py` whenever a setting is added.

### Changing one variable in place, without a rebuild

The production `.env` lives at `$NAS_DEPLOY_DIR/.env` and `deploy_nas.sh` never touches it,
so a setting can be changed on its own. `scp` is blocked on the NAS — pipe over ssh, and
prefix any command needing `docker` with the PATH export.

```bash
source scripts/deploy.env
NAS_PATH='export PATH=/var/packages/ContainerManager/target/usr/bin:$PATH'

# 1. Read first — never append blind, the key may already be set.
ssh "$NAS_SSH" "grep -n MISTRAL_MODEL $NAS_DEPLOY_DIR/.env" || echo "not set"

# 2. Append (or edit) it.
echo 'MISTRAL_MODEL=mistral-medium-latest' | ssh "$NAS_SSH" "cat >> $NAS_DEPLOY_DIR/.env"

# 3. Recreate the container with the new interpolated environment.
ssh "$NAS_SSH" "$NAS_PATH; cd $NAS_DEPLOY_DIR && docker compose up -d"
```

No image build, no registry push, no Alembic run. Rollback is deleting the line and
repeating step 3.

## 3. Deploy

```bash
cd backend
./scripts/deploy_nas.sh
```

The script builds the image, pushes it to the registry named by `$REGISTRY`, SSHes to
`$NAS_SSH`, brings the compose stack up, and runs `alembic upgrade head`. All three come
from `scripts/deploy.env`; the script exits naming the variable if one is missing.

## 4. Verify

```bash
source scripts/deploy.env
curl -s "$PUBLIC_URL/health"
# expect: {"status":"ok","version":...,"llm":{"provider":...,"model":...,"credentials":true}}
```

**Read the `llm` block, do not just check for `ok`.** Confirm `provider` and `model` are the
ones you intended: a wrong model there *is* the 2026-09-09 outage, which returned 502 to every
client for two days while this endpoint answered `ok`. It costs nothing — the model is
resolved locally, never by calling the provider. `credentials: true` only means a key is set;
it does not prove the account may call that model, which is why the real request below still
matters.

Then exercise a real path — the unauthenticated analysis endpoint is the quickest end-to-end
proof, since it crosses TLS, the app, and the LLM provider:

```bash
curl -s -X POST "$PUBLIC_URL/comments/zapzap-analysis" \
  -H 'Content-Type: application/json' \
  -d @scripts/sample_payload.json | head -20
```

A `503` means the configured provider reports itself unavailable — almost always missing
credentials for the selected `LLM_PROVIDER`. A `502` is an upstream provider error.

Logs: `ssh nas` then `docker logs -f <api-container>`. There is **no monitoring or
alerting** — logs are all there is.

## 5. Rollback

```bash
./scripts/deploy_nas.sh --rollback <git-sha>
```

**Alembic does not roll back with it.** If the bad deploy applied a migration, downgrade
deliberately (`alembic downgrade -1`) and only after checking the revision's `downgrade()`
actually preserves data. When in doubt, restore from the latest `pg_dump` in `/backups`
instead.

## Local development

```bash
cd backend
docker compose up -d          # db + api on :8000 + backup sidecar
uvicorn app.main:app --reload # or run it directly; docs at /docs
```
The dev compose file and Dockerfile default to 2 workers, which is fine locally.

## Checklist

- [ ] `ruff check .` and `pytest -m 'not integration'` clean
- [ ] Any new Alembic revision read, not just generated
- [ ] `.env.example` updated if `app/config.py` gained a setting
- [ ] `CORS_ORIGINS` correct, never `*`
- [ ] Still exactly 1 uvicorn worker in `docker-compose.prod.yml`
- [ ] `/health` returns ok **and names the intended `llm.provider` and `llm.model`**
- [ ] A real endpoint exercised, not just `/health` — only a real call proves the account's
      tier allows the configured model
