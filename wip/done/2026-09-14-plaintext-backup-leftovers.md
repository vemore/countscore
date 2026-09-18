# Plaintext dumps outlive backup encryption, and NAS ACLs widen backup files

**Status:** done (2026-09-18) — closed by fix/backend-hardening. `.llmwiki/Deployment.md` now says ad-hoc dumps go through `countscore-backup --once` and that on the NAS the ACL on `backups/`, restricted to the container user and the admin, governs access; the script comment says the same. The NAS steps (deleting `pre_0002_20260913.sql.gz`, restricting the `backups/` ACL with `synoacltool`) are applied at deploy by the orchestrator, from the pull request body.

- **Noted:** 2026-09-14 — smoke-testing the encrypted `db-backup` sidecar (#40) in production
- **Theme:** backend-hardening
- **Area:** backend
- **Blocks release:** no — the NAS is private, and the new dumps are encrypted

`backups/pre_0002_20260913.sql.gz` on the NAS is a plaintext `pg_dump` taken by hand before
the `0002_sync_contract` migration. Its name matches none of the retention patterns in
`backend/backup/countscore-backup.sh` (`countscore_*.dump.gz.age`, `countscore_*.sql.gz`,
`countscore_*.dump.gz`), so it is never deleted and keeps every `share_token` in clear. The
`countscore_*.sql.gz` files age out on their own within 7 days.

Second observation: `ls -l backups/` lists the new `countscore_*.dump.gz.age` as
`-rwxrwxrwx+`, like the older files, although the script writes with `umask 077`. The
Synology ACL inherited from the shared folder (`+`) overrides the mode bits. Encrypted, so
low impact, but the script's "only the owner may read a dump" comment and
`.llmwiki/Deployment.md` do not hold on the NAS.

**Fix:** delete `pre_0002_20260913.sql.gz` once the user agrees (or encrypt it with `age` and
keep it), and record in `.llmwiki/Deployment.md` that ad-hoc dumps must go through
`countscore-backup --once`. Check `synoacltool -get` on `backups/` and restrict it to the
container user, or document that the ACL, not the mode, governs access there.

**Decided (2026-09-18, refinement):** delete `backups/pre_0002_20260913.sql.gz`, and
restrict the `backups/` ACL to the container user.

**Acceptance:**
- `pre_0002_20260913.sql.gz` is gone from the NAS.
- `synoacltool -get` on `backups/` grants access to the container user (and the admin) only.
- `.llmwiki/Deployment.md` says ad-hoc dumps go through `countscore-backup --once`, and that the ACL governs access on the NAS.
