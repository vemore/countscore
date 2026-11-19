# The migrate-first deploy script misreports a few failures

- **Noted:** 2026-11-19 — independent review of #279 (`fix/deploy-nas-migrate-first-and-verify`)
- **Theme:** deploy-safety
- **Area:** backend
- **Blocks release:** no

All four are Low and none is a regression; `backend/scripts/deploy_nas.sh` is the file.

1. **`up --wait` and the public check blame the new image for other failures.** `--wait` also
   waits on `db-backup`, and `check_health` goes through the public proxy. A sidecar that does
   not turn healthy, or a Web Station outage, prints "new image did not come up healthy"; with
   no migration the script then rolls back a good `api` image.
2. **A dropped SSH connection after `alembic upgrade` applied** leaves `MIGRATED=0`: the EXIT
   trap pins the previous image and says the schema is untouched. The old `api` keeps serving,
   safe under expand/contract, but the message is wrong.
3. **`PREVIOUS` is any `api` container `compose ps -q` lists**, a crash-looping one included:
   the pin and the automatic rollback then target an already-broken image.
4. **`compose run api` ensures its `db` dependency**, so a changed `db` service in a freshly
   copied `compose.yaml` can recreate `db` before the "swap", with the old `api` still serving.

**Fix:** name the failing service in the message (`docker compose ps` after a failed `--wait`)
and try the public URL only after the local one; read `alembic current` again before claiming
the schema is untouched; take `PREVIOUS` only from a running, healthy container.

**Acceptance:**
- A `db-backup` that never turns healthy is reported as the sidecar, and the `api` image is
  not rolled back.
- After a failure past `alembic upgrade`, the message states the schema state it read.
