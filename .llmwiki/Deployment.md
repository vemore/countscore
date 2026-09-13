# Deployment

> Scope: production topology and environment. For the procedure, use the `backend-deploy` skill.
> Related: [[Backend]] · [[Security]] · [[Web]] · [[LlmProviders]]
> Updated: 2026-09-13

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

> **Status: Outdated** (2026-09-13) — the PWA now has one; see *The PWA* below.

### The PWA — served by the `api` container, deployed by `scripts/deploy_web.sh`

The PWA lives on the **backend's own host**, under the sub-path `PWA_BASE_PATH` (e.g.
`/countscore`). Web Station is untouched: its portal already proxies the whole host to
`127.0.0.1:8087`, and FastAPI answers both the API and the static build. Same origin, so
the PWA needs no `CORS_ORIGINS` entry and there is no mixed-content case. Procedure: the
`web-deploy` skill. Route behaviour: [[Api]]; CSP: [[Security]].

On the NAS the build lives in `$NAS_DEPLOY_DIR/pwa/current`, bind-mounted **read-only** as
`/srv/pwa` (the parent — see Decisions) and served from `PWA_DIR=/srv/pwa/current`.
`deploy_nas.sh` creates `pwa/` as the SSH user before `docker compose up`.

`scripts/deploy_web.sh` has no config of its own: `NAS_SSH` and `NAS_DEPLOY_DIR` come from
`backend/scripts/deploy.env`, and **`PWA_BASE_PATH` is read over ssh from the NAS `.env`**,
the value the container mounts at, so the build's `--base-href` cannot disagree with it.
It refuses a build containing any `.md` file or lacking `sqlite3.wasm` / `drift_worker.js`,
streams a tarball into `pwa/current.new`, and renames it into place, keeping one
`pwa/current.prev`. No container restart: the folder is read per request.

```bash
scripts/deploy_web.sh --dry-run    # build + checks, prints the remote commands
scripts/deploy_web.sh
scripts/deploy_web.sh --rollback   # swap pwa/current.prev back
```

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
| `GEMINI_API_KEY` / `GEMINI_MODEL` / `GEMINI_BASE_URL` | Gemini | — / `gemini-2.5-flash` / — |
| `MISTRAL_API_KEY` / `MISTRAL_MODEL` / `MISTRAL_BASE_URL` | Mistral | — / `mistral-medium-latest` / — |
| `CORS_ORIGINS` | Allowed origins, CSV. `*` is rejected at startup | prod URL |
| `RL_PER_MINUTE` / `RL_PER_HOUR` / `RL_PER_DAY` | Per-device rate limit | `6` / `30` / `100` |
| `IP_RL_PER_MINUTE` / `IP_RL_PER_HOUR` | Anonymous IP rate limit on the LLM endpoints | `5` / `30` |
| `GROUP_RL_PER_MINUTE` / `GROUP_RL_PER_HOUR` | IP rate limit on group create/join, own bucket | `3` / `10` |
| `HSTS_ENABLED` | Send `Strict-Transport-Security`. `true` in prod, `false` for local http | `false` |
| `MAX_BODY_BYTES` | Request body cap (413 above) | `262144` |
| `PWA_BASE_PATH` | Sub-path the api container serves the PWA under, e.g. `/countscore`. Empty = no PWA. Also read by `scripts/deploy_web.sh` for `--base-href` | `` |
| `PWA_DIR` | Build folder inside the container. Compose pins it to `/srv/pwa/current` | `/srv/pwa/current` |
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
  **Accepted as is (2026-09-13):** a hostname behind TLS and an RFC 1918 address, not a
  credential. Renaming the DDNS host was the cheap way to kill the old name; it was not
  judged worth a certificate re-issue.
- **The dev compose file reads the whole `.env` (2026-09-13).** Its `api` service used to
  list six variables by hand and none of the LLM ones, so the ZapZap endpoint answered 503
  on every local `docker compose up`. It now uses `env_file: .env`, as production effectively
  does, and overrides only `DATABASE_URL` to reach the `db` host. A hand-kept list drifted
  once; a file cannot.
- **The PWA is served by the backend, not by Web Station (2026-09-13).** The owner wanted
  it on the backend's subdomain. A Web Station reverse-proxy portal maps a whole hostname
  to one destination, with no per-path rule in the UI, and a second portal on the same
  hostname and port is not allowed — so `/countscore/` on that host could only reach
  FastAPI. The alternatives were a hand-written nginx `location` in the files Web Station
  generates (root-only, and liable to vanish on a DSM update or the next portal edit, on a
  NAS with no alerting) or moving the API under a path (breaking every configured app).
  Serving static files from the one-worker uvicorn costs little for a handful of family
  users, and buys same-origin: no CORS entry, no mixed content. A first version of this
  change targeted a separate Web Station folder with its own untracked config; it was
  replaced before merge.
- **The build is mounted by its parent folder, and swapped by rename.** A bind mount pins
  the inode of the directory it names: mounting `pwa/current` itself would keep serving the
  old release after `mv`. Mounting `pwa/` makes a rename visible at once, so a half-copied
  release is never served and a rollback is two renames. Upload is a tarball over ssh
  because `scp` is blocked on the NAS — the constraint `deploy_nas.sh` already works around.
- **`PWA_BASE_PATH` has a single home, the NAS `.env`.** The container needs it to mount
  and the build needs it for `--base-href`; a copy in `deploy.env` would be a second value
  free to drift, and a mismatch is a blank page. The deploy script reads it over ssh.
- **The `.md` refusal exists because `web/CLAUDE.md` was published** with every build until
  the same day; it moved to `.claude/rules/web.md`.
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
