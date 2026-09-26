# The only copy of the backups is on the machine they back up

- **Noted:** 2026-09-25 — comparing the NAS deploy with standard deployment practice
- **Theme:** backend-hardening
- **Area:** backend
- **Blocks release:** no

The `db-backup` sidecar writes its daily dumps to `$NAS_DEPLOY_DIR/backups`
(`.llmwiki/Deployment.md` *Backups*) — the same NAS that holds the Postgres volume. Nothing in
the repository or the wiki copies them elsewhere. A dead disk array, a ransomware infection
or a lost NAS takes the database and every backup at once: the 3-2-1 rule (three copies, two
media, one off-site) is not met. And no restore is ever exercised: the one proof that a dump
decrypts and restores is a manual step in `backend-deploy` §4.

The dumps are age-encrypted to a key that never touches the NAS, so an off-site copy leaks
nothing readable.

**Fix:** copy `backups/` off the NAS daily — Synology Hyper Backup or `rclone` to a cloud
bucket, or a pull from another machine — with its own retention; document the target (not
the credentials) in `.llmwiki/Deployment.md`. Add a periodic restore test on the machine
holding the private key: decrypt the latest dump, `pg_restore` into a throwaway Postgres,
count rows in a few tables.

**State of the art** (web search, 2026-09-26): the 3-2-1 rule (three copies, two media, one
off-site) is now commonly extended to 3-2-1-1-0 — one copy immutable (object-lock or
air-gapped) against ransomware that targets backup repositories, plus an automated restore
test reporting zero errors — endorsed by CISA's #StopRansomware guide and NIST SP 800-209 /
800-53. We depart on two points at this scale: the off-site copy here is encrypted rather
than object-locked or air-gapped, since the private key never touches the NAS anyway; and
the restore test stays a periodic manual command, not a daily automated sandbox restore,
proportionate to one self-hosted instance rather than an enterprise fleet.
Sources: [AvePoint, 3-2-1 backup rule guide](https://www.avepoint.com/blog/backup/3-2-1-backup-rule),
[SentinelOne, 3-2-1 backup strategy](https://www.sentinelone.com/cybersecurity-101/cybersecurity/3-2-1-backup-strategy/).

**Acceptance:**
- A dump written by the sidecar is found off the NAS within 24 hours.
- A documented command restores the latest off-site dump into a scratch Postgres and
  reports row counts.

**Open question:** which off-site target — Hyper Backup to a cloud provider, or another
machine at home?
