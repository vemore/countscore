# CI never builds `backend/Dockerfile.backup`

**Status:** done (2026-09-18) — closed by `chore/ci-image-and-osv-gates`. The `image` CI job now builds `backend/Dockerfile.backup`, runs `age --version` and `pg_dump --version` (major 17) in it, requires `countscore-backup --once` with no recipient to exit non-zero, and runs `docker compose config --quiet` on `docker-compose.prod.yml` (dummy `POSTGRES_*`/`CORS_ORIGINS`) and `docker-compose.yml` (`.env.example`), failing on any warning. `backend/*` already routed both paths to `image`; `scripts/ci_scope_selftest.sh` now pins it.

- **Noted:** 2026-09-14 — while adding the age-encrypted `db-backup` image (feat/encrypted-backups)
- **Theme:** backend-hardening
- **Area:** backend
- **Blocks release:** no

The sidecar image (`postgres:17-alpine3.23` + `apk add age~1.2` + `backend/backup/countscore-backup.sh`)
is built only by `backend/scripts/deploy_nas.sh`, at deploy time. A bad pin — the Alpine tag
retired, `age` moving past 1.2 in that branch — surfaces as a failed production deploy, not
as a red pull request. `backend/tests/test_backup_script.py` covers the script with stubs,
but never the real `age`/`pg_dump` in the image. `.github/workflows/ci.yml` was owned by
another pull request (chore/backend-ci-hardening) when this was noted, so it was left alone.

The same gap covers the compose files: nothing in CI runs `docker compose config` on
`docker-compose.yml` / `docker-compose.prod.yml`.

**Fix:** in the `image` job, `docker build -f backend/Dockerfile.backup backend`, then run
the image with `--entrypoint sh -c 'age --version && pg_dump --version'`, and
`countscore-backup --once` with no recipient must exit non-zero. Add
`docker compose -f backend/docker-compose.prod.yml config --quiet` with dummy
`POSTGRES_*` / `CORS_ORIGINS`.

**Acceptance:**
- The `image` CI job builds `backend/Dockerfile.backup` and fails when it does not build.
- In that image, `age --version && pg_dump --version` exits 0.
- `docker compose -f backend/docker-compose.prod.yml config --quiet` passes with dummy environment values.
- `scripts/ci_scope.sh` sets `image=true` for `backend/backup/*` and `backend/Dockerfile.backup`.
