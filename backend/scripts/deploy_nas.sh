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
#      LLM_PROVIDER + the matching provider key.)
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

echo "==> Building $IMAGE:$VERSION"
docker build -t "$IMAGE:$VERSION" -t "$IMAGE:latest" -f Dockerfile .

echo "==> Pushing to registry"
docker push "$IMAGE:$VERSION"
docker push "$IMAGE:latest"

echo "==> Copying compose.yaml to the NAS (scp is blocked, so we pipe via ssh)"
# pwa/ is created here, as the SSH user, so Docker does not create it root-owned on
# first start and lock scripts/deploy_web.sh out of it.
ssh "$NAS_SSH" "mkdir -p $NAS_DEPLOY_DIR/backups $NAS_DEPLOY_DIR/pwa"
cat docker-compose.prod.yml | ssh "$NAS_SSH" "cat > $NAS_DEPLOY_DIR/compose.yaml"

echo "==> Pulling and starting on the NAS"
ssh "$NAS_SSH" \
    "$NAS_PATH_EXPORT && cd $NAS_DEPLOY_DIR && docker compose pull && docker compose up -d"

echo "==> Applying database migrations"
ssh "$NAS_SSH" \
    "$NAS_PATH_EXPORT && cd $NAS_DEPLOY_DIR && docker compose exec -T api alembic upgrade head"

echo "==> Deployed $IMAGE:$VERSION"
echo "    Local (NAS): http://127.0.0.1:8087/health"
echo "    Configure Web Station to reverse-proxy $PUBLIC_URL -> http://localhost:8087"
