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
`db` (Postgres 17-alpine) and a `db-backup` sidecar (its own image,
`backend/Dockerfile.backup`) writing a daily age-encrypted `pg_dump` with 7-day rotation.
Caddy is no longer used.

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

Also required: **`BACKUP_AGE_RECIPIENT`**, the age public key the `db-backup` sidecar
encrypts every dump to. Without it the sidecar refuses to run (restart loop, reason in its
logs) and `deploy_nas.sh` refuses to deploy.

Keep `.env.example` in sync with `app/config.py` whenever a setting is added.

### The backup key pair — first deploy of encrypted backups, or a key rotation

Generate the pair **off the NAS** and never copy the private key there:

```bash
age-keygen -o countscore-backup.key      # prints "Public key: age1..."; keep this file safe
source scripts/deploy.env
ssh "$NAS_SSH" "grep -n BACKUP_AGE_RECIPIENT $NAS_DEPLOY_DIR/.env" || echo "not set"
echo 'BACKUP_AGE_RECIPIENT=age1...' | ssh "$NAS_SSH" "cat >> $NAS_DEPLOY_DIR/.env"
```

Then deploy (section 3): the recipient must be in the `.env` *before* the new sidecar starts.
Losing the private key loses every backup; rotating it means older dumps still need the old
key until they age out (7 days).

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

The script checks that the NAS `.env` has `BACKUP_AGE_RECIPIENT=age1…`, builds two images
from `HEAD` — `countscore` (`Dockerfile`) and `countscore-backup` (`Dockerfile.backup`),
both tagged `<short sha>` and `latest` — pushes them to the registry named by `$REGISTRY`,
SSHes to `$NAS_SSH`, brings the compose stack up, prints the `db-backup` status and last log
lines, and runs `alembic upgrade head`. All three come
from `scripts/deploy.env`; the script exits naming the variable if one is missing.

**Before the upgrade, a pending revision gets its own dump.** When `alembic current` differs
from `alembic heads` in the new container, the script has the `db-backup` sidecar write
`backups/premigration_<UTC ts>_<from>-to-<to>.dump.gz.age` (age-encrypted like the daily
dumps, outside their 7-day retention), and stops without migrating if that fails. There is no
staging: this dump and CI's upgrade/`downgrade base`/upgrade round trip stand in for one.
Note the file name it prints — §5 needs it. Delete it by hand once the release has proved
itself.

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
curl -s -X POST "$PUBLIC_URL/comments/game-analysis" \
  -H 'Content-Type: application/json' \
  -d @scripts/sample_payload.json | head -20
```

A `503` has two causes, told apart by the body: `LLM provider not configured` is missing
credentials for the selected `LLM_PROVIDER`; `upstream LLM rate-limited` (with `Retry-After`)
means the configuration is right but the provider account is out of quota. A `502` is any
other upstream provider error.

Check the backup sidecar is up, not restarting, and can actually write a dump:

```bash
NAS_PATH='export PATH=/var/packages/ContainerManager/target/usr/bin:$PATH'
ssh "$NAS_SSH" "$NAS_PATH; cd $NAS_DEPLOY_DIR && docker compose ps db-backup && \
  docker compose logs --tail 5 db-backup && \
  docker compose exec -T db-backup countscore-backup --once && ls -l backups | tail -3"
```

Expect `encrypting to age1…` in the logs, `backup done: countscore_<ts>.dump.gz.age`, and
that file in `backups/` with mode `-rw-------`. Prove it decrypts **on the machine holding
the private key**, never on the NAS:
`ssh "$NAS_SSH" "cat $NAS_DEPLOY_DIR/backups/<file>" | age -d -i countscore-backup.key | gunzip | pg_restore --list | head`.

Logs: `ssh nas` then `docker logs -f <api-container>`. There is **no monitoring or
alerting** — logs are all there is.

## 5. Rollback

```bash
./scripts/deploy_nas.sh --rollback <git-sha>
```

**Alembic does not roll back with it.** If the bad deploy applied a migration, undo the
schema by restoring the `premigration_*` dump §3 took — not by `alembic downgrade`, whose
`downgrade()` CI only proves on an empty database. Writes made since the deploy are lost.
Roll the image back first, stop the API, empty the schema (a `--clean` restore would leave
the tables the migration added), restore — decrypting off the NAS, with the private key —
and start again:

```bash
source scripts/deploy.env
NAS_PATH='export PATH=/var/packages/ContainerManager/target/usr/bin:$PATH'
./scripts/deploy_nas.sh --rollback <git-sha>
ssh "$NAS_SSH" "$NAS_PATH; cd $NAS_DEPLOY_DIR && docker compose stop api && docker compose exec -T db \
  sh -c 'psql -v ON_ERROR_STOP=1 -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" -c \"DROP SCHEMA public CASCADE; CREATE SCHEMA public;\"'"
ssh "$NAS_SSH" "cat $NAS_DEPLOY_DIR/backups/premigration_<ts>_<from>-to-<to>.dump.gz.age" \
  | age -d -i countscore-backup.key | gunzip \
  | ssh "$NAS_SSH" "$NAS_PATH; cd $NAS_DEPLOY_DIR && docker compose exec -T db \
      sh -c 'pg_restore --exit-on-error -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\"'"
ssh "$NAS_SSH" "$NAS_PATH; cd $NAS_DEPLOY_DIR && docker compose up -d && \
  docker compose exec -T api alembic current"      # expect <from>
```

The same pipe restores a daily `countscore_<ts>.dump.gz.age` when no pre-migration dump fits.

Dumps written before 2026-09-14 are plaintext `countscore_<ts>.sql.gz`:
`gunzip -c <file> | pg_restore …`.

`--rollback` only retags the `api` image: `db-backup` stays on `countscore-backup:latest`.
Rolling back to a sha older than encrypted backups still keeps them encrypted.

## Local development

```bash
cd backend
docker compose up -d          # db + api on :8000 + backup sidecar (needs BACKUP_AGE_RECIPIENT in .env)
EXPOSE_DOCS=true uvicorn app.main:app --reload # or run it directly; docs at /docs
```
The Dockerfile runs one worker and the dev compose file inherits it — the same as production.

## Checklist

- [ ] `ruff check .` and `pytest -m 'not integration'` clean
- [ ] Any new Alembic revision read, not just generated; its `premigration_*` dump name noted
- [ ] `.env.example` updated if `app/config.py` gained a setting
- [ ] `CORS_ORIGINS` correct, never `*`
- [ ] `BACKUP_AGE_RECIPIENT` set in the NAS `.env` (public key only), and `db-backup` running,
      not restarting — `countscore-backup --once` wrote a `.dump.gz.age`
- [ ] `PWA_BASE_PATH` still set in the NAS `.env` if the PWA is published (see `web-deploy`)
- [ ] Still exactly 1 uvicorn worker in `docker-compose.prod.yml`
- [ ] `/health` returns ok **and names the intended `llm.provider` and `llm.model`**
- [ ] A real endpoint exercised, not just `/health` — only a real call proves the account's
      tier allows the configured model
