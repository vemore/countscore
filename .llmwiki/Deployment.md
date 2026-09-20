# Deployment

> Scope: production topology and environment. For the procedure, use the `backend-deploy` skill.
> Related: [[Backend]] · [[Security]] · [[Web]] · [[LlmProviders]]
> Updated: 2026-09-20

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
| `db-backup` | Sidecar: daily `pg_dump \| gzip \| age` → `/backups/*.dump.gz.age`, 7-day rotation. Image `localhost:5050/countscore-backup:latest` (`backend/Dockerfile.backup`). Refuses to run without `BACKUP_AGE_RECIPIENT` — see *Backups* below. |

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
./scripts/deploy_nas.sh                    # check BACKUP_AGE_RECIPIENT → build api + backup images → push → up → [pre-migration dump] → alembic upgrade
./scripts/deploy_nas.sh --rollback <sha>   # roll back to a git sha (the image only, never the schema)
```

**Migrations have no staging** (decided 2026-09-14: the owner is production's sole user, and
the daily dump exists). Two things stand in for one. CI's `backend` job migrates an empty
Postgres up, `downgrade base`, up again, then `alembic check`. And when `alembic current`
differs from `alembic heads`, `deploy_nas.sh` has the `db-backup` sidecar write
`backups/premigration_<UTC ts>_<from>-to-<to>.dump.gz.age` before upgrading — encrypted,
outside the 7-day retention glob, and no upgrade if it fails. A bad migration is undone by
restoring that dump over an emptied `public` schema, not by `alembic downgrade`
(`backend-deploy` §5).

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

### Backups — age-encrypted, and refused without a key

The `db-backup` sidecar (`docker-compose.prod.yml`, `docker-compose.yml`) runs
`backend/backup/countscore-backup.sh`, baked into its own image, `backend/Dockerfile.backup`
(`postgres:17-alpine3.23` plus Alpine's `age~1.2`; `postgres:17-alpine` has no `age`). In
production the image is `localhost:5050/countscore-backup:latest`, built and pushed by
`deploy_nas.sh` next to the api image and tagged with the same short sha; the dev compose file
builds it. It runs as `1027:100` in production, as before. The `image` CI job builds it too,
runs the real `age --version` and `pg_dump --version` (major 17) in it, and requires
`countscore-backup --once` without a recipient to exit non-zero, so a retired base tag or an
`age` pin gone stale turns a pull request red instead of a deploy ([[Testing]]).

Every day at 03:00 UTC (`BACKUP_AT_SECONDS`, default `10800`) it writes
`pg_dump -Fc | gzip | age -r "$BACKUP_AGE_RECIPIENT"` into `./backups` —
`$NAS_DEPLOY_DIR/backups` on the NAS — as `countscore_<UTC timestamp>.dump.gz.age`, mode
`0600` (`umask 077`). Guarantees, each covered by `backend/tests/test_backup_script.py`
against stub `pg_dump`/`age`:

- **No recipient, no dump.** An empty `BACKUP_AGE_RECIPIENT`, or one `age` rejects, makes the
  script exit non-zero *at container start* — the container restart-loops with the reason in
  `docker compose logs db-backup` — and refuse each run. There is no plaintext fallback.
- **No truncated file.** The pipe runs under `set -o pipefail` into a hidden
  `.countscore_<ts>.dump.gz.age.partial`, renamed into place only when all three stages
  succeed and the file is non-empty; otherwise it is deleted and the run logs `backup FAILED`.
  A failed run never stops the loop: the next attempt is the next day.
- **Retention.** Files older than 7 days (`BACKUP_RETENTION_DAYS`) are deleted, matching
  `countscore_*.dump.gz.age` and the plaintext `countscore_*.sql.gz` / `countscore_*.dump.gz`
  written before encryption, so the last plaintext dumps on the NAS age out by themselves a
  week after the first encrypted deploy. The sweep runs after the rename, with `-exec rm`
  (Ubuntu's BusyBox `find` has no `-delete`); a failed sweep is logged, not a failed backup.
- `docker compose stop` is immediate: the script traps `TERM` and sleeps in the background.
- `countscore-backup --once` takes one backup now and exits:
  `docker compose exec db-backup countscore-backup --once`. **Every ad-hoc dump goes through
  it** (or through `deploy_nas.sh`'s pre-migration dump), never a hand-run `pg_dump`: a dump
  taken by hand is plaintext, and a name outside the retention globs is never swept — the
  plaintext `pre_0002_20260913.sql.gz` sat in `backups/` from 2026-09-13 until it was deleted
  by hand.

**On the NAS `backups/` is in plain Linux mode, owner only.** The script writes with
`umask 077`, and that holds only because `backups/` carries no Synology ACL: `ls -la` shows
`drwx------` owned by the container user (uid 1027, gid 100, the `db-backup` sidecar's
`user:`, which is also the SSH user) and every dump `-rw-------`, with no `+`; `synoacltool
-get "$NAS_DEPLOY_DIR/backups"` prints `It's Linux mode`. A file written into a Linux-mode
directory inherits no ACL, so each new dump is `0600`. Root and DSM administrators bypass mode
bits anyway. Until 2026-09-18 the folder inherited the shared folder's ACL (`everyone` read,
another household user write) and the dumps listed as `-rwxrwxrwx+`.

- **Restore it** if DSM (a permission edit in File Station, a shared-folder ACL change)
  re-applies an ACL — `ls -la` shows `+` again, or `synoacltool -get` lists entries — as the
  owner, no sudo: `chmod 700 backups && chmod 600 backups/*`. `chmod` on a Synology ACL file
  converts it back to Linux mode.
- **Never run `synoacltool -enforce-inherit` on a folder whose ACL has no `is_inherit`.** On
  2026-09-18 that wiped the folder's ACL entirely and left it `d---------`, locking out the
  owner: the sidecar failed with `Permission denied` until the `chmod` above.
- On a host without ACLs nothing is needed: the `0600` mode is what protects a dump. Whoever
  self-hosts on a Synology checks `ls -la` once after the first backup.

The connection comes from libpq's variables, which the compose file sets from the
`POSTGRES_*` values: `PGHOST=db`, `PGUSER`, `PGPASSWORD`, `PGDATABASE`.

**The key pair.** Only the public key (`age1…`) is on the server, in the NAS `.env`. The
private key (`AGE-SECRET-KEY-…`) is generated and kept off the NAS
(`age-keygen -o countscore-backup.key`); without it the backups cannot be read by anyone,
the operator included. `deploy_nas.sh` refuses to deploy when the NAS `.env` has no
`BACKUP_AGE_RECIPIENT=age1…` line.

**Restore**, on the machine holding the private key (the content is `pg_dump`'s custom
format, so `pg_restore`, not `psql`):

```bash
age -d -i countscore-backup.key countscore_<ts>.dump.gz.age | gunzip | pg_restore -h … -U … -d …
```

A dump still holds the whole database — every group's `share_token` in clear, all shared
games, rounds, scores, player names, analyses and comments, the `change_log` payloads, device
labels and `last_seen_at` (device tokens only as argon2 hashes). Encryption moves the secret
from the backup files to the private key: **a leaked private key is a leaked backup.** Then
rotate every group's invite code from that group's owner device (Settings → Group → *New
code*, or `POST /groups/me/rotate-share-token`; only the owner may rotate, any other device
gets a 403 — [[Api]]) and re-share it; devices already joined are unaffected.

> **Status: Outdated** (2026-09-14) — until `feat/encrypted-backups` this section was titled
> *Backups — plain files that let their reader join every group*: the sidecar ran an inline
> `sh -c` loop on `postgres:17-alpine`, writing unencrypted `countscore_<ts>.sql.gz` with no
> `umask` and no temp file, restored with `gunzip -c <file> | pg_restore`. Its loop compared
> the time with `-le`, so a dump failing within its first second would have run again for
> the rest of that second; the script uses `-lt`.

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
It refuses a build containing any `.md` file or lacking `index.html`, `main.dart.js`,
`sqlite3.wasm` or `drift_worker.js` (`scripts/check_web_build.sh`, shared with the Pages
workflow), streams a tarball into `pwa/current.new`, and renames it into place, keeping one
`pwa/current.prev`. No container restart: the folder is read per request. Browsers that
visited before keep running the previous build from their service-worker cache until they
take the reload the app offers ([[Web]], "Offline and updates"); a rollback is a new build id
for them like any deploy.

```bash
scripts/deploy_web.sh --dry-run    # build + checks, prints the remote commands
scripts/deploy_web.sh
scripts/deploy_web.sh --rollback   # swap pwa/current.prev back
```

### The PWA on GitHub Pages — `.github/workflows/deploy-pages.yml`

A second, independent copy of the PWA at `<owner>.github.io/<repo>/`, published by GitHub
Actions after a merge to `main` that touches the app, or on a manual run; it also carries the
privacy policy page, which Pages served from `main:/docs` before. Nothing on the NAS is
involved, and no backend URL is built in. It is **cross-origin** to every backend: an operator
whose users run it lists `https://<owner>.github.io` in `CORS_ORIGINS` and serves over
`https://`. Details: [[Web]].

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
| `MAX_BUDGET_CENTS` | Ceiling the group owner may set through `PATCH /groups/me/settings`. Unset = `DEFAULT_BUDGET_CENTS` | unset |
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
| `GROUP_OWNER_DORMANT_DAYS` | Days a group owner may go unseen before a member may claim the role (`POST /groups/me/owner/claim`) | `30` |
| `AUTH_FAIL_RL_PER_MINUTE` / `AUTH_FAIL_RL_PER_HOUR` | Failed device-token checks per IP before a 429 | `10` / `60` |
| `SYNC_PUSH_RL_PER_MINUTE` / `SYNC_PUSH_RL_PER_HOUR` | `/sync/push` calls per device before a 429 (the app pushes batches of 100) | `60` / `1200` |
| `EXPOSE_DOCS` | Serve `/docs`, `/redoc`, `/openapi.json`. Leave off in production | `false` |
| `HSTS_ENABLED` | Send `Strict-Transport-Security`. `true` in prod, `false` for local http | `false` |
| `MAX_BODY_BYTES` | Request body cap (413 above) | `262144` |
| `PWA_BASE_PATH` | Sub-path the api container serves the PWA under, e.g. `/countscore`. Empty = no PWA. Also read by `scripts/deploy_web.sh` for `--base-href` | `` |
| `PWA_DIR` | Build folder inside the container. Compose pins it to `/srv/pwa/current` | `/srv/pwa/current` |
| `LOG_LEVEL` | | — |
| `TRUSTED_PROXY_IPS` | Proxy addresses (CSV) whose `X-Real-IP` / `X-Forwarded-Proto` the app believes | `172.28.87.1` in prod compose, empty elsewhere |
| `BACKUP_AGE_RECIPIENT` | `db-backup` only: the age public key (`age1…`) every dump is encrypted to. Unset = the sidecar refuses to run and `deploy_nas.sh` refuses to deploy. Never the private key | required |

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
- **Backups are encrypted with age to a public key, and refused without one (2026-09-14).**
  Closed `wip/done/2026-09-13-encrypt-backups.md`. age over gpg: one static binary in Alpine,
  a one-line recipient, no keyring or trust model to get wrong on a NAS. Asymmetric over a
  passphrase: the server that writes the dumps never holds what decrypts them, so reading the
  NAS is no longer reading every group. Refusal over a plaintext fallback: a silent fallback
  is the state being fixed, and a restart-looping container is visible where a missing
  variable is not. The loop moved from an inline compose `command` into a script so the
  refusal and the no-truncated-file rule could be tested without Postgres. The gzip stage is
  kept (custom format already compresses) so the restore line stays the obvious one.
- **`backups/` is owner-only in plain Linux mode on the NAS, not under an ACL (decided
  2026-09-18).** Closed `wip/done/2026-09-14-plaintext-backup-leftovers.md` and
  `wip/done/2026-09-18-backup-docs-linux-mode.md`. The dumps are encrypted, so the inherited
  world-readable ACL leaked nothing readable, but it made the script's "only the owner may read
  a dump" false on the one host it runs on. The first plan was a restricted ACL for the
  container user and `administrators`, pushed with `synoacltool -enforce-inherit`; that call
  wiped the ACL and locked the owner out, and the recovery, `chmod 700`/`chmod 600`, turned the
  folder into Linux mode — which is simpler than an ACL, needs no sudo to check or restore, and
  makes `umask 077` hold by itself. Kept. The hand-taken plaintext `pre_0002_20260913.sql.gz`
  was deleted rather than encrypted: the `0002_sync_contract` migration it guarded has been
  live since 2026-09-13.
- **Backups are `pg_dump` on a cron sidecar with 7-day rotation**, not a managed service.
  The dataset is small and the recovery story is "copy a file back".
- **The backups' contents were written down before being encrypted (2026-09-14).** The
  2026-09-13 security review flagged that they carry every live `share_token`. Documenting it
  took minutes and tells each self-hosting operator what they are storing; encrypting them
  (a public key in the sidecar, the private key off the NAS) changes the restore procedure
  and stayed open in `wip/done/2026-09-13-encrypt-backups.md` until `feat/encrypted-backups`
  closed it the same day (above).
- **`LLM_PROVIDER` defaults to `bedrock` in code**, but production has been run on
  `mistral`; `backend/README.md` describes only the default. Check the actual `.env` on the
  NAS before assuming which provider answered a given request. **This bit (2026-09-09 →
  2026-09-11):** production set `LLM_PROVIDER=mistral` but not `MISTRAL_MODEL`, inherited the
  code default `mistral-large-latest` — a model the account's tier no longer allows — and
  every analysis 502'd for two days while `/health` still said `ok`. Closed on 2026-09-11 by
  three changes together: the default is now `mistral-medium-latest`, `/health` reports the
  resolved model, and production sets `MISTRAL_MODEL` explicitly. See `wip/done/ARCHIVE-2026-09.md` and
  [[LlmProviders]]. **Confirmed by the deploy (2026-09-11):** production picked up
  `mistral-medium-latest` from the *compose* default alone — the NAS `.env` was never edited —
  which proves the compose copy, not `app/config.py`, is the one production reads.
- **The compose file carries its own defaults, and they win.** `docker-compose.prod.yml`
  interpolates `${MISTRAL_MODEL:-…}` from the NAS `.env`, so a default written only in
  `app/config.py` never reaches production. Every provider default therefore exists twice and
  the two must move together — that duplication is what made the 2026-09-09 fix a five-file
  change rather than a one-line one.
