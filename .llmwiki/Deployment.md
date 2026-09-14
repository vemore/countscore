# Deployment

> Scope: production topology and environment. For the procedure, use the `backend-deploy` skill.
> Related: [[Backend]] · [[Security]] · [[Web]] · [[LlmProviders]]
> Updated: 2026-09-14

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
| `api` | FastAPI/uvicorn, **1 worker**. Image from the local NAS registry, `$REGISTRY/countscore:latest`. Port `127.0.0.1:8087:8000`. `--no-proxy-headers`; `X-Real-IP` believed from `TRUSTED_PROXY_IPS` only. |
| `db` | Postgres 17-alpine, mounted volume. |
| `db-backup` | Sidecar cron: `pg_dump → /backups`, 7-day rotation. **Unencrypted — see *Backups* below.** |

The single worker is **not** a resource decision: `ip_rate_limiter.py` holds its state in
process memory, so more than one worker would silently multiply the effective rate limit.
The Dockerfile's `CMD` also runs one worker, and the dev compose file inherits it. See
[[LlmProviders]].

> **Status: Outdated** (2026-09-14) — until this date this paragraph said the local
> `docker-compose.yml` and the Dockerfile default to 2 workers. The Dockerfile had already
> moved to `--workers 1`, and the dev compose file sets no `command`.

### The image — `backend/Dockerfile`

Every self-hosting user deploys this image, so it is locked down by default:

- **Two stages.** `builder` copies the `uv` binary from `ghcr.io/astral-sh/uv:0.12.6` and
  runs `uv sync --locked --no-dev --no-install-project` into `/app/.venv`. `runtime` is a
  fresh `python:3.13-slim` that receives only that venv plus `app/`, `alembic/` and
  `alembic.ini`. No `apt-get`: every dependency ships a manylinux wheel, so neither
  `build-essential` nor `libpq-dev` is needed, and no compiler is in the image.
- **Locked dependencies.** Production resolves exactly `backend/uv.lock`, as CI does.
  `--locked` fails the build if the lock is stale. `--no-dev` leaves out the `dev` group
  (testcontainers, httpx-ws), and extras are never installed, so pytest, ruff and mypy
  stay out too. `--no-install-project` is used because the app runs from `/app` as source,
  and building the project would need the `README.md` that `.dockerignore` excludes.
- **Non-root.** `USER app`, uid/gid **10001**, no home and no login shell. The code and the
  venv belong to root, so the process cannot write to its own filesystem. It never needs to:
  the only mount is the read-only PWA, which `deploy_web.sh` makes world-readable
  (`chmod -R a+rX`).
- `PATH` starts with `/app/.venv/bin`. The compose healthcheck (`python -c …`) and
  `docker compose exec -T api alembic upgrade head` therefore work unchanged.

Measured on 2026-09-14: 600 MB before, 271 MB after. Checked against a Postgres 17
container: `alembic upgrade head`, `/health`, a PWA file under `PWA_BASE_PATH`,
`POST /groups` 201, and the compose healthcheck passing. The `image` CI job re-checks
uid ≠ 0, no compiler, no pytest, and that the app imports.

```bash
cd backend
./scripts/deploy_nas.sh                    # build → push registry → up → alembic upgrade
./scripts/deploy_nas.sh --rollback <sha>   # roll back to a git sha
```

**Client address.** Web Station reaches the API through the published port, so inside the
container the peer is the compose network's gateway. The network is pinned to
`172.28.87.0/24` so that gateway is a known `172.28.87.1`, and `TRUSTED_PROXY_IPS` names it.
The portal config (`/usr/local/etc/nginx/conf.d-available/<uuid>.w3conf` on the NAS) sets
`X-Real-IP $remote_addr` and `X-Forwarded-Proto $scheme` but **not** `X-Forwarded-For`, which
therefore arrives exactly as the client wrote it. So the app believes `X-Real-IP` from the
gateway only (`app/services/trusted_proxy.py`), and uvicorn runs with `--no-proxy-headers` so
it never reads `X-Forwarded-For` at all.

The first deploy after the subnet was pinned needed `docker compose down && docker compose up
-d` on the NAS (Compose will not change an existing network's IPAM). Verify from outside,
since access logs are off (`uvicorn.access` at WARNING in `app/main.py`): four `POST
/groups/join` with a bogus `share_token` and a different `X-Forwarded-For` each must answer
`404, 404, 404, 429` — four `404`s mean a client-written header is believed again. Then one
bogus join from the NAS itself to `http://127.0.0.1:8087` (peer: the gateway, no `X-Real-IP`)
must answer `404`: a `429` there means every caller shares the gateway's bucket, i.e.
`TRUSTED_PROXY_IPS` does not match the peer.

> **Status: Outdated** (2026-09-13) — the first fix, `fix/ip-spoofing-zapzap-payload`, set
> `FORWARDED_ALLOW_IPS=172.28.87.1` on the belief that Web Station *appends* to
> `X-Forwarded-For`. It does not set that header at all, so uvicorn took the client's value:
> the check above answered `404` four times on the first production deploy. Replaced the same
> day by `fix/trust-x-real-ip`.

Dev uses `docker-compose.yml` (no TLS, local Postgres): `docker compose up -d` — db plus
api on 8000 plus the backup sidecar.

Verify with `curl "$PUBLIC_URL/health"` → `{"status": "ok", "version": …, "llm":
{"provider": …, "model": …, "credentials": …}}`. The `llm` block reports the model the
container actually resolved, which is the check that would have caught the 2026-09-09
outage — see [[LlmProviders]].

There is **no deployment path for the Flutter web app** in this repo — no vhost, no
hosting config. Only the backend container is covered. See [[Web]].

> **Status: Outdated** (2026-09-13) — the PWA now has one; see *The PWA* below.

### Backups — plain files that let their reader join every group

The `db-backup` sidecar (`docker-compose.prod.yml`, `docker-compose.yml`) runs at 03:00 UTC
`pg_dump -Fc | gzip` into `./backups` — `$NAS_DEPLOY_DIR/backups` on the NAS — as
`countscore_<timestamp>.sql.gz`, and deletes files older than 7 days. **Nothing encrypts
them.** A dump holds the whole database, which includes:

- **every group's `share_token` in clear** (`groups.share_token`). The invite code is the only
  thing `POST /groups/join` asks for, so anyone holding a backup — the NAS account that can
  read the folder, a copy on another disk, a cloud sync of `docker/` — can join any group
  and pull its games. This is the part that turns a backup leak into access.
- all shared games, rounds, scores, player names, analyses and group comments, and the
  `change_log` payloads that repeat them;
- device labels and `last_seen_at`. Device tokens are **not** usable: only their argon2
  hash (`devices.token_hash`) is stored.

What an operator should do, until the backups are encrypted (`TODO.md`):

- treat `backups/` and every copy of it as a secret, like `.env`. The sidecar sets no
  `umask`, so the files get the container's default mode; check who else on the NAS can read
  the folder;
- after a backup has leaked, rotate the invite code of every group (Settings → Group →
  *New code*, or `POST /groups/me/rotate-share-token` from one device per group), then
  re-share it. Rotating invalidates the leaked codes; devices already joined are unaffected.

Despite the `.sql.gz` name the content is `pg_dump`'s **custom format**, gzipped: restore
with `gunzip -c <file> | pg_restore -h … -U … -d …`, not with `psql`.

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
| `MAX_BUDGET_CENTS` | Ceiling a member may set through `PATCH /groups/me/settings`. Unset = `DEFAULT_BUDGET_CENTS` | unset |
| `MAX_STREAMS_PER_DEVICE` | Concurrent `/sync/stream` connections per device (1013 beyond) | `3` |
| `LLM_PROVIDER` | ZapZap provider: `bedrock` \| `gemini` \| `mistral` | `bedrock` |
| `BEDROCK_MODEL_ID` | Bedrock model | `us.meta.llama3-3-70b-instruct-v1:0` |
| `AWS_REGION` / `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_SESSION_TOKEN` | Bedrock credentials | required if bedrock |
| `GEMINI_API_KEY` / `GEMINI_MODEL` / `GEMINI_BASE_URL` | Gemini | — / `gemini-2.5-flash` / — |
| `MISTRAL_API_KEY` / `MISTRAL_MODEL` / `MISTRAL_BASE_URL` | Mistral | — / `mistral-medium-latest` / — |
| `CORS_ORIGINS` | Allowed origins, CSV. `*` is rejected at startup | prod URL |
| `RL_PER_MINUTE` / `RL_PER_HOUR` / `RL_PER_DAY` | Per-device rate limit | `6` / `30` / `100` |
| `IP_RL_PER_MINUTE` / `IP_RL_PER_HOUR` | Anonymous IP rate limit on the LLM endpoints | `5` / `30` |
| `GROUP_RL_PER_MINUTE` / `GROUP_RL_PER_HOUR` | IP rate limit on group create/join, own bucket | `3` / `10` |
| `AUTH_FAIL_RL_PER_MINUTE` / `AUTH_FAIL_RL_PER_HOUR` | Failed device-token checks per IP before a 429 | `10` / `60` |
| `SYNC_PUSH_RL_PER_MINUTE` / `SYNC_PUSH_RL_PER_HOUR` | `/sync/push` calls per device before a 429 (the app pushes batches of 100) | `60` / `1200` |
| `EXPOSE_DOCS` | Serve `/docs`, `/redoc`, `/openapi.json`. Leave off in production | `false` |
| `HSTS_ENABLED` | Send `Strict-Transport-Security`. `true` in prod, `false` for local http | `false` |
| `MAX_BODY_BYTES` | Request body cap (413 above) | `262144` |
| `PWA_BASE_PATH` | Sub-path the api container serves the PWA under, e.g. `/countscore`. Empty = no PWA. Also read by `scripts/deploy_web.sh` for `--base-href` | `` |
| `PWA_DIR` | Build folder inside the container. Compose pins it to `/srv/pwa/current` | `/srv/pwa/current` |
| `LOG_LEVEL` | | — |
| `TRUSTED_PROXY_IPS` | Proxy addresses (CSV) whose `X-Real-IP` / `X-Forwarded-Proto` the app believes | `172.28.87.1` in prod compose, empty elsewhere |

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
- **First production deploy of the PWA (2026-09-13), image `1570d90`.** Order that worked:
  `PWA_BASE_PATH` appended to the NAS `.env` *before* `deploy_nas.sh`, so the recreated
  container mounted it on its first start; then `scripts/deploy_web.sh`. Observed over
  HTTPS through the existing Web Station portal, with no portal change: the sub-path
  answers 200 with the PWA CSP and `Cache-Control: no-cache`, `sqlite3.wasm` is served as
  `application/wasm`, `CLAUDE.md` is a 404, `/health` still reports `gemini` /
  `gemini-2.5-flash`, and `/comments/zapzap-analysis` answered 200. In a browser: no console
  error, a game created before a reload was there after it. `pwa/` came out owned by the
  SSH user, and the container sees it read-only. The sub-path itself is in the NAS `.env`,
  not here.
- **The image was hardened because it is everyone's image (2026-09-14).** Before this date
  it ran as root, kept `build-essential` and `libpq-dev`, and ran `pip install -e .` from
  `pyproject.toml`. Each build therefore resolved its own dependency set, and only CI honoured
  `uv.lock`. The 2026-09-13 security review listed it in the hardening bundle, and once the
  backend became something each user self-hosts, the default image was the one that mattered.
  uid 10001 is outside the range a NAS or desktop hands to real accounts, so a host file
  that happens to match it is unlikely. It does not need to match the NAS user: the container
  writes nothing to a bind mount.
- **Backups are `pg_dump` on a cron sidecar with 7-day rotation**, not a managed service.
  The dataset is small and the recovery story is "copy a file back".
- **The backups' contents were written down before being encrypted (2026-09-14).** The
  2026-09-13 security review flagged that they carry every live `share_token`. Documenting it
  took minutes and tells each self-hosting operator what they are storing; encrypting them
  (a public key in the sidecar, the private key off the NAS) changes the restore procedure
  and stays open in `TODO.md`.
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
