# The backup docs say an ACL governs backups/ on the NAS, which is in plain Linux mode

**Status:** done (2026-09-18) — closed by docs/backups-owner-only-mode. `.llmwiki/Deployment.md` § *Backups* and its Decisions bullet, the `backend-deploy` skill §4 and the comment in `backend/backup/countscore-backup.sh` now describe `backups/` as owner-only Linux mode, how to check it (`ls -la`, `synoacltool -get` → `It's Linux mode`), how to restore it (`chmod 700`/`chmod 600` as the owner) and warn against `synoacltool -enforce-inherit`.

- **Noted:** 2026-09-18 — applying the NAS steps of `wip/done/2026-09-14-plaintext-backup-leftovers.md` after `fix/backend-hardening` (#102) merged
- **Theme:** docs
- **Area:** docs
- **Blocks release:** no

#102 documented that a restricted Synology ACL (container user + `administrators`) governs
`backups/`. Applying it, `synoacltool -enforce-inherit` on the folder (whose `is_inherit` had
just been removed) wiped its ACL and left it `d---------`; the sidecar failed with
`Permission denied`. Recovery was `chmod 700 backups` and `chmod 600 backups/*` as the owner,
which turned the folder into Linux mode: `drwx------` uid 1027, dumps `-rw-------`, no ACL,
and a new `countscore-backup --once` writes `-rw-------`. The docs describe an ACL that does
not exist and a `sudo synoacltool -get` check that no longer applies.

**Fix:** describe the Linux-mode reality, the check, the restore and the `-enforce-inherit`
warning in Deployment.md, the skill and the script comment.

**Acceptance:**
- `grep -rn "synoacltool" .llmwiki .claude backend` finds no claim that an ACL governs `backups/`.
- Deployment.md names `chmod 700`/`chmod 600` as the restore and warns against `-enforce-inherit`.
