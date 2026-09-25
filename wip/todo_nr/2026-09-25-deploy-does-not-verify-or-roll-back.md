# A backend deploy neither waits for health nor rolls back on failure

- **Noted:** 2026-09-25 — comparing the NAS deploy with standard deployment practice
- **Theme:** deploy-safety
- **Area:** backend
- **Blocks release:** no

After `docker compose up -d`, `backend/scripts/deploy_nas.sh:89` sleeps 5 seconds and prints
the `db-backup` logs; nothing checks that the new `api` container became healthy, although
`docker-compose.prod.yml:79` defines a healthcheck. The verification (`/health`, a real
`/comments` call) lives in the `backend-deploy` skill §4 and depends on the session reading
it. A container that crash-loops after the deploy exits the script with status 0.

`docker compose up -d --wait --wait-timeout <s>` blocks until every service with a
healthcheck is healthy and exits non-zero otherwise.

**Fix:** `up -d --wait --wait-timeout 90` in place of `up -d` + `sleep 5`; then
`curl -fsS "$PUBLIC_URL/health"`, checking the reported version (see
[[2026-09-25-deployed-version-is-not-identifiable]]). On failure, redeploy the previous tag
automatically and exit non-zero. Automatic rollback applies only when no migration ran;
otherwise stop and point at `backend-deploy` §5.

**Acceptance:**
- `deploy_nas.sh` has no `sleep` and calls `up` with `--wait`.
- An image whose `/health` fails makes the script exit non-zero and leaves the previous image
  running.
