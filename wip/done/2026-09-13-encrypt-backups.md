# Daily backups hold every `share_token` in clear

**Status:** done (2026-09-14) — closed by feat/encrypted-backups. The `db-backup` sidecar now
runs `backend/backup/countscore-backup.sh` in its own image (`backend/Dockerfile.backup`,
postgres + age): `pg_dump -Fc | gzip | age -r $BACKUP_AGE_RECIPIENT` into
`countscore_<ts>.dump.gz.age`, temp file then rename, and it refuses to run without a
recipient; `deploy_nas.sh` builds the image and refuses to deploy without the variable.
Restore line in `.llmwiki/Deployment.md` *Backups*.

- **Noted:** 2026-09-13 — backend security review, LOW hardening bundle
- **Theme:** backend-hardening
- **Area:** backend
- **Blocks release:** no

`./backups` holds plain gzip `pg_dump`s. Documented on 2026-09-14 in `.llmwiki/Deployment.md`,
*Backups*; encryption is still to do.

**Fix:** pipe the dump through `age -r <public key>` in the `db-backup` sidecar (recipient
in the NAS `.env`, private key kept off the NAS), name files `.dump.gz.age`, rewrite the
restore line to `age -d -i <key> | gunzip | pg_restore`. Needs an image shipping `age` —
`postgres:17-alpine` does not.
