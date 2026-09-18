#!/bin/sh
# CountScore db-backup sidecar: a daily, age-encrypted pg_dump.
#
#   pg_dump -Fc | gzip | age -r "$BACKUP_AGE_RECIPIENT"  ->  $BACKUP_DIR/countscore_<UTC ts>.dump.gz.age
#
# A dump holds every group's share_token in clear, so this script REFUSES to write
# one without a recipient: no BACKUP_AGE_RECIPIENT, no dump, and a non-zero exit.
# There is deliberately no plaintext fallback.
#
# The connection comes from libpq's own variables (PGHOST, PGUSER, PGPASSWORD,
# PGDATABASE), set by the compose file.
#
# Usage: countscore-backup           # loop: wait for BACKUP_AT_SECONDS UTC, dump, repeat
#        countscore-backup --once    # one dump now, then exit (manual run, smoke test)
#
# Restore (on a machine holding the private key, never on the NAS):
#   age -d -i <key file> countscore_<ts>.dump.gz.age | gunzip | pg_restore -h … -U … -d …
set -eu
# BusyBox ash (the image) and bash support pipefail; without it a failed pg_dump
# would still produce a valid, empty-looking encrypted file.
if ! (set -o pipefail) 2>/dev/null; then
    echo "countscore-backup: this shell has no 'set -o pipefail'; refusing to run" >&2
    exit 1
fi
set -o pipefail

BACKUP_DIR="${BACKUP_DIR:-/backups}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
# Seconds after midnight UTC. 10800 = 03:00.
AT_SECONDS="${BACKUP_AT_SECONDS:-10800}"

log() { echo "countscore-backup: $*"; }
fail() { echo "countscore-backup: ERROR: $*" >&2; }

# Refuses loudly unless the recipient is set AND age accepts it, so a typo in the
# .env shows up at container start rather than as a missing file a week later.
check_recipient() {
    if [ -z "${BACKUP_AGE_RECIPIENT:-}" ]; then
        fail "BACKUP_AGE_RECIPIENT is not set. Refusing to write an unencrypted backup."
        fail "Set it in .env to an age public key (age1...) and recreate the container."
        return 1
    fi
    if ! echo probe | age -r "$BACKUP_AGE_RECIPIENT" >/dev/null; then
        fail "age rejects BACKUP_AGE_RECIPIENT. Refusing to back up."
        return 1
    fi
}

backup_once() {
    check_recipient || return 1

    ts=$(date -u +%Y%m%d_%H%M%S)
    name="countscore_${ts}.dump.gz.age"
    # Hidden name, outside the retention glob: a failed pipe never leaves a file that
    # looks like a backup.
    tmp="$BACKUP_DIR/.${name}.partial"

    # Only the owner (the container user) may read a dump: mode 0600. This holds only
    # where the directory carries no ACL — on the Synology NAS backups/ is in plain
    # Linux mode (drwx------), and an inherited ACL would override the mode
    # (.llmwiki/Deployment.md, Backups).
    umask 077
    rm -f "$BACKUP_DIR"/.countscore_*.partial

    if pg_dump -Fc | gzip | age -r "$BACKUP_AGE_RECIPIENT" >"$tmp" && [ -s "$tmp" ]; then
        mv "$tmp" "$BACKUP_DIR/$name"
    else
        rm -f "$tmp"
        fail "backup FAILED (pg_dump, gzip or age exited non-zero); no file written"
        return 1
    fi

    # Encrypted dumps, plus the plaintext ones written before encryption (.sql.gz, and
    # .dump.gz for good measure), age out after RETENTION_DAYS. `-exec rm` rather than
    # `-delete`, which some BusyBox builds lack. The dump is already safe on disk, so a
    # failed sweep is reported, not treated as a failed backup.
    log "backup done: $name"
    if ! find "$BACKUP_DIR" -maxdepth 1 -type f \
        \( -name 'countscore_*.dump.gz.age' -o -name 'countscore_*.sql.gz' -o -name 'countscore_*.dump.gz' \) \
        -mtime +"$RETENTION_DAYS" -exec rm -f {} +; then
        fail "retention sweep failed; old backups were not deleted"
    fi
}

if [ "${1:-}" = "--once" ]; then
    backup_once
    exit $?
fi

# Loop mode. Fail at start rather than sleep until 03:00 to discover a missing key:
# the container exits, restarts, and says why in `docker logs`.
check_recipient || exit 1
log "encrypting to ${BACKUP_AGE_RECIPIENT}; next run at ${AT_SECONDS}s after 00:00 UTC"

# PID 1 ignores SIGTERM without a handler, so `docker compose stop` would wait out its
# 10 s grace period. The sleep runs in the background so the trap fires at once.
trap 'log "stopping"; exit 0' TERM INT

while true; do
    # BusyBox date has no GNU "-d 'tomorrow 03:00'": compute the delay from the epoch.
    secs=$(( $(date +%s) % 86400 ))
    # Strictly before: a run that finishes within its own start second must wait for
    # tomorrow, not start again (with -le, a sub-second failure looped all second long).
    if [ "$secs" -lt "$AT_SECONDS" ]; then
        delay=$(( AT_SECONDS - secs ))
    else
        delay=$(( 86400 - secs + AT_SECONDS ))
    fi
    sleep "$delay" &
    wait $!
    # A failed run is logged and retried the next day; it never stops the loop.
    backup_once || true
done
