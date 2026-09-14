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
#   ./scripts/deploy_nas.sh              # build + push + deploy current HEAD
#   ./scripts/deploy_nas.sh --rollback <git-sha>
set -euo pipefail

CONFIG="$(dirname "$0")/deploy.env"
# shellcheck source=/dev/null
[[ -f "$CONFIG" ]] && source "$CONFIG"

# Fail loudly and by name rather than deploying somewhere unintended.
: "${REGISTRY:?set REGISTRY in backend/scripts/deploy.env (see deploy.env.example)}"
: "${NAS_SSH:?set NAS_SSH in backend/scripts/deploy.env (see deploy.env.example)}"
: "${NAS_DEPLOY_DIR:?set NAS_DEPLOY_DIR in backend/scripts/deploy.env (see deploy.env.example)}"
PUBLIC_URL="${PUBLIC_URL:-<your public URL>}"

IMAGE="$REGISTRY/countscore"
# The db-backup sidecar: postgres client + age (Dockerfile.backup). Built from the same
# commit and tagged alike, so compose.yaml's :latest always pairs with the api image.
BACKUP_IMAGE="$REGISTRY/countscore-backup"
NAS_PATH_EXPORT="export PATH=/var/packages/ContainerManager/target/usr/bin:\$PATH"

# Run from the backend/ directory (where the Dockerfile lives).
cd "$(dirname "$0")/.."

if [[ "${1:-}" == "--rollback" ]]; then
    TAG="${2:?Usage: deploy_nas.sh --rollback <git-sha>}"
    echo "==> Rolling back to $TAG"
    ssh "$NAS_SSH" \
        "$NAS_PATH_EXPORT && cd $NAS_DEPLOY_DIR && \
         sed -i 's|localhost:5050/countscore:.*|localhost:5050/countscore:$TAG|' compose.yaml && \
         docker compose up -d"
    exit 0
fi

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

echo "==> Pulling and starting on the NAS"
ssh "$NAS_SSH" \
    "$NAS_PATH_EXPORT && cd $NAS_DEPLOY_DIR && docker compose pull && docker compose up -d"

echo "==> db-backup sidecar"
sleep 5
ssh "$NAS_SSH" \
    "$NAS_PATH_EXPORT && cd $NAS_DEPLOY_DIR && docker compose ps db-backup && docker compose logs --tail 5 db-backup"

# A pending revision gets its own dump first: --rollback retags the image but never the
# schema, and the daily dump may be a day old. Taken by the db-backup sidecar (pg_dump 17
# + age, connection from its PG* env) so it is encrypted like every other dump, and named
# outside the sidecar's countscore_* retention glob so it is kept. No dump, no upgrade.
nas_alembic() {
    ssh "$NAS_SSH" "$NAS_PATH_EXPORT && cd $NAS_DEPLOY_DIR && docker compose exec -T api alembic $1" \
        2>/dev/null | awk 'NF { r = $1 } END { print r }'
}
CURRENT_REV=$(nas_alembic current)
HEAD_REV=$(nas_alembic heads)
[[ -n "$HEAD_REV" ]] || { echo "error: could not read alembic heads from the new api container" >&2; exit 1; }
if [[ "$CURRENT_REV" != "$HEAD_REV" ]]; then
    DUMP="premigration_$(date -u +%Y%m%d_%H%M%S)_${CURRENT_REV:-base}-to-${HEAD_REV}.dump.gz.age"
    echo "==> Pending migration ${CURRENT_REV:-base} -> $HEAD_REV: dumping to backups/$DUMP"
    ssh "$NAS_SSH" "$NAS_PATH_EXPORT && cd $NAS_DEPLOY_DIR && docker compose exec -T db-backup sh -euc '
        set -o pipefail; umask 077
        pg_dump -Fc | gzip | age -r \"\$BACKUP_AGE_RECIPIENT\" > /backups/.$DUMP.partial
        [ -s /backups/.$DUMP.partial ] && mv /backups/.$DUMP.partial /backups/$DUMP'"
else
    echo "==> Schema already at $HEAD_REV: no pre-migration dump"
fi

echo "==> Applying database migrations"
ssh "$NAS_SSH" \
    "$NAS_PATH_EXPORT && cd $NAS_DEPLOY_DIR && docker compose exec -T api alembic upgrade head"

echo "==> Deployed $IMAGE:$VERSION"
echo "    Local (NAS): http://127.0.0.1:8087/health"
echo "    Configure Web Station to reverse-proxy $PUBLIC_URL -> http://localhost:8087"
