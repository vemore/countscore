#!/bin/bash
# Build, push and deploy the CountScore backend to a Synology NAS.
#
# The host, registry and SSH alias are deliberately NOT in this file: they are
# one person's infrastructure, and the repository is public. Put them in
# scripts/deploy.env (gitignored) — copy scripts/deploy.env.example — or export
# the same variables in the environment.
#
# Prereqs (one-time):
#   - dev /etc/docker/daemon.json has "insecure-registries": ["$REGISTRY"]
#   - an SSH alias for the NAS, configured in ~/.ssh/config
#   - logged in to the registry: docker login "$REGISTRY"
#   - the production .env placed on the NAS once (secrets stay off the repo):
#       cat .env | ssh "$NAS_SSH" "cat > $NAS_DEPLOY_DIR/.env"
#     (must set POSTGRES_*, CORS_ORIGINS=<your public URL>,
#      LLM_PROVIDER + the matching provider key, and BACKUP_AGE_RECIPIENT — the
#      age public key the db-backup sidecar encrypts to; without it that container
#      refuses to start. The private key stays off the NAS.)
#
# Usage:
#   ./scripts/deploy_nas.sh              # build + push + migrate + swap + verify current HEAD
#   ./scripts/deploy_nas.sh --rollback <git-sha>
#
# Order of a deploy, and why:
#   1. pull the new images; the running containers keep the image they started from;
#   2. a pending revision gets an encrypted dump first — no dump, no upgrade;
#   3. `alembic upgrade head` from a one-off container of the new image;
#   4. only then swap: `up -d --wait`, then GET $PUBLIC_URL/health.
# A failed dump or upgrade stops before step 4, so the previous api container keeps serving
# (its schema is untouched: env.py runs every revision in one transaction). A new api that
# never turns healthy is replaced by the previous image automatically, but only when no
# migration ran; after one, the old code would meet the new schema, so the script stops and
# points at the backend-deploy skill §5. Every revision must therefore keep the previous
# release's code working (expand/contract, the db-migration skill).
#
# Every remote command below is built on this side on purpose, so SC2029 is noise here.
# shellcheck disable=SC2029
set -euo pipefail

CONFIG="$(dirname "$0")/deploy.env"
# shellcheck source=/dev/null
[[ -f "$CONFIG" ]] && source "$CONFIG"

# Fail loudly and by name rather than deploying somewhere unintended.
: "${REGISTRY:?set REGISTRY in backend/scripts/deploy.env (see deploy.env.example)}"
: "${NAS_SSH:?set NAS_SSH in backend/scripts/deploy.env (see deploy.env.example)}"
: "${NAS_DEPLOY_DIR:?set NAS_DEPLOY_DIR in backend/scripts/deploy.env (see deploy.env.example)}"

IMAGE="$REGISTRY/countscore"
# The db-backup sidecar: postgres client + age (Dockerfile.backup). Built from the same
# commit and tagged alike, so compose.yaml's :latest always pairs with the api image.
BACKUP_IMAGE="$REGISTRY/countscore-backup"
# The api image as compose.yaml names it: the NAS reaches its registry on localhost.
NAS_IMAGE="localhost:5050/countscore"
# The image the api container ran before this deploy, tagged on the NAS only, never pushed.
PREVIOUS_TAG="pre-deploy"
NAS_PATH_EXPORT="export PATH=/var/packages/ContainerManager/target/usr/bin:\$PATH"

# Run from the backend/ directory (where the Dockerfile lives).
cd "$(dirname "$0")/.."

# One command in the deploy directory on the NAS, with Container Manager's docker on PATH.
nas() {
    ssh "$NAS_SSH" "$NAS_PATH_EXPORT && cd $NAS_DEPLOY_DIR && $1"
}

# Point compose.yaml's api service at another tag of the image. Does not restart anything.
pin_api() {
    nas "sed -i 's|$NAS_IMAGE:.*|$NAS_IMAGE:$1|' compose.yaml"
}

# Recreate what changed and block until every healthcheck passes; non-zero otherwise.
up_wait() {
    nas "docker compose up -d --wait --wait-timeout 90"
}

if [[ "${1:-}" == "--rollback" ]]; then
    TAG="${2:?Usage: deploy_nas.sh --rollback <git-sha>}"
    echo "==> Rolling back to $TAG"
    pin_api "$TAG"
    up_wait
    exit 0
fi

# Checked through the reverse proxy, after the swap: a container healthy on its own port
# behind a broken portal is still an outage.
: "${PUBLIC_URL:?set PUBLIC_URL in backend/scripts/deploy.env (see deploy.env.example)}"

check_health() {
    echo "==> GET $PUBLIC_URL/health"
    curl -fsS "$PUBLIC_URL/health" --max-time 15 && echo
}

VERSION=$(git rev-parse --short HEAD)

# The db-backup sidecar refuses to run without an age recipient, by design: a dump holds
# every share_token in clear. Catch it here rather than as a restart loop on the NAS.
echo "==> Checking BACKUP_AGE_RECIPIENT in the NAS .env"
if ! ssh "$NAS_SSH" "grep -Eq '^BACKUP_AGE_RECIPIENT=age1[0-9a-z]+[[:space:]]*$' $NAS_DEPLOY_DIR/.env"; then
    echo "error: $NAS_DEPLOY_DIR/.env on the NAS has no BACKUP_AGE_RECIPIENT=age1..." >&2
    echo "       Generate a key pair OFF the NAS (age-keygen -o countscore-backup.key), keep" >&2
    echo "       the private key safe, and append its public key to the NAS .env." >&2
    exit 1
fi

echo "==> Building $IMAGE:$VERSION"
docker build -t "$IMAGE:$VERSION" -t "$IMAGE:latest" -f Dockerfile .

echo "==> Building $BACKUP_IMAGE:$VERSION"
docker build -t "$BACKUP_IMAGE:$VERSION" -t "$BACKUP_IMAGE:latest" -f Dockerfile.backup .

echo "==> Pushing to registry"
docker push "$IMAGE:$VERSION"
docker push "$IMAGE:latest"
docker push "$BACKUP_IMAGE:$VERSION"
docker push "$BACKUP_IMAGE:latest"

echo "==> Copying compose.yaml to the NAS (scp is blocked, so we pipe via ssh)"
# pwa/ is created here, as the SSH user, so Docker does not create it root-owned on
# first start and lock scripts/deploy_web.sh out of it.
ssh "$NAS_SSH" "mkdir -p $NAS_DEPLOY_DIR/backups $NAS_DEPLOY_DIR/pwa"
cat docker-compose.prod.yml | ssh "$NAS_SSH" "cat > $NAS_DEPLOY_DIR/compose.yaml"

PREVIOUS=""   # $NAS_IMAGE:$PREVIOUS_TAG once the running api image carries that tag
SWAPPED=0     # set when `up` starts: from then on the previous container may be gone
MIGRATED=0    # set once `alembic upgrade head` applied a pending revision
DUMP=""

# A deploy that stops before the swap leaves the previous api container serving, but after
# the pull compose.yaml's :latest names the new image: the next `docker compose up -d` (an
# .env change, skill §2) would start it on the unmigrated schema. Pin the previous one.
on_exit() {
    local rc=$?
    if ((rc != 0 && !SWAPPED)) && [[ -n "$PREVIOUS" ]]; then
        echo "error: deploy of $VERSION stopped before the swap; the previous api container is still serving." >&2
        if pin_api "$PREVIOUS_TAG"; then
            echo "       compose.yaml now names $PREVIOUS, so a later 'docker compose up -d' keeps it." >&2
        else
            echo "       warning: could not pin compose.yaml to $PREVIOUS; do not run 'docker compose up -d'." >&2
        fi
    fi
    return "$rc"
}
trap on_exit EXIT

echo "==> Tagging the running api image $NAS_IMAGE:$PREVIOUS_TAG on the NAS"
RUNNING=$(nas "docker compose ps -q api")
if [[ -n "$RUNNING" ]]; then
    nas "docker tag \$(docker inspect -f '{{.Image}}' $RUNNING) $NAS_IMAGE:$PREVIOUS_TAG"
    PREVIOUS="$NAS_IMAGE:$PREVIOUS_TAG"
else
    echo "    no api container is running: nothing to roll back to if this deploy fails"
fi

echo "==> Pulling on the NAS (nothing restarts yet)"
nas "docker compose pull"

# Read from one-off containers of the new image: `run --rm` starts db if it is not running,
# publishes no port, and leaves the serving api container alone.
nas_alembic() {
    nas "docker compose run --rm -T api alembic $1" | awk 'NF { r = $1 } END { print r }'
}
CURRENT_REV=$(nas_alembic current) || { echo "error: could not read alembic current" >&2; exit 1; }
HEAD_REV=$(nas_alembic heads) || { echo "error: could not read alembic heads" >&2; exit 1; }
[[ -n "$HEAD_REV" ]] || { echo "error: the new image reports no alembic head" >&2; exit 1; }

if [[ "$CURRENT_REV" != "$HEAD_REV" ]]; then
    # A pending revision gets its own dump first: --rollback retags the image but never the
    # schema, and the daily dump may be a day old. Taken by the db-backup service (pg_dump 17
    # + age, connection from its PG* env) so it is encrypted like every other dump, and named
    # outside the sidecar's countscore_* retention glob so it is kept. A one-off container,
    # because the sidecar need not be running yet (first deploy). No dump, no upgrade.
    DUMP="premigration_$(date -u +%Y%m%d_%H%M%S)_${CURRENT_REV:-base}-to-${HEAD_REV}.dump.gz.age"
    echo "==> Pending migration ${CURRENT_REV:-base} -> $HEAD_REV: dumping to backups/$DUMP"
    nas "docker compose run --rm -T --entrypoint sh db-backup -euc '
        set -o pipefail; umask 077
        pg_dump -Fc | gzip | age -r \"\$BACKUP_AGE_RECIPIENT\" > /backups/.$DUMP.partial
        [ -s /backups/.$DUMP.partial ] && mv /backups/.$DUMP.partial /backups/$DUMP'"

    echo "==> Applying database migrations, before the swap"
    nas "docker compose run --rm -T api alembic upgrade head"
    MIGRATED=1
else
    echo "==> Schema already at $HEAD_REV: no dump, no migration"
fi

echo "==> Starting the new containers, waiting up to 90 s for their healthchecks"
SWAPPED=1
if ! { up_wait && check_health; }; then
    echo "error: $IMAGE:$VERSION did not come up healthy." >&2
    if ((MIGRATED)); then
        echo "       Migration ${CURRENT_REV:-base} -> $HEAD_REV ran, so the previous image is NOT put" >&2
        echo "       back automatically: it would run against the migrated schema. Follow the" >&2
        echo "       backend-deploy skill §5 (Rollback) with the dump backups/$DUMP." >&2
        [[ -n "$PREVIOUS" ]] && echo "       The previous image is tagged $PREVIOUS on the NAS." >&2
        exit 1
    fi
    if [[ -z "$PREVIOUS" ]]; then
        echo "       No previous api image to roll back to." >&2
        exit 1
    fi
    echo "==> No migration ran: rolling back to $PREVIOUS" >&2
    pin_api "$PREVIOUS_TAG"
    if up_wait && check_health; then
        echo "error: deploy of $VERSION failed; the previous image is serving again." >&2
    else
        echo "error: deploy of $VERSION failed, and the rollback to $PREVIOUS is not healthy either:" >&2
        echo "       read 'docker compose ps' and 'docker compose logs api' on the NAS." >&2
    fi
    exit 1
fi

echo "==> db-backup sidecar"
nas "docker compose ps db-backup && docker compose logs --tail 5 db-backup"

echo "==> Deployed $IMAGE:$VERSION"
[[ -n "$DUMP" ]] && echo "    Pre-migration dump: backups/$DUMP (backend-deploy §5 needs it on a rollback)"
echo "    Local (NAS): http://127.0.0.1:8087/health"
echo "    Configure Web Station to reverse-proxy $PUBLIC_URL -> http://localhost:8087"
