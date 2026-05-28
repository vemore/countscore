#!/bin/bash
# Build, push and deploy the CountScore backend to the Synology NAS.
#
# Prereqs (one-time):
#   - dev /etc/docker/daemon.json has "insecure-registries": ["192.168.1.25:5050"]
#   - SSH alias `nas` configured (port 8022, user vincent)
#   - logged in to the registry: docker login 192.168.1.25:5050
#   - the production .env placed on the NAS once (secrets stay off the repo):
#       cat .env | ssh nas "cat > /volume1/docker/countscore/.env"
#     (must set POSTGRES_*, CORS_ORIGINS=https://countscore.ombivince.synology.me,
#      LLM_PROVIDER + the matching provider key.)
#
# Usage:
#   ./scripts/deploy_nas.sh              # build + push + deploy current HEAD
#   ./scripts/deploy_nas.sh --rollback <git-sha>
set -euo pipefail

REGISTRY="192.168.1.25:5050"
IMAGE="$REGISTRY/countscore"
NAS_SSH="nas"
NAS_DEPLOY_DIR="/volume1/docker/countscore"
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
ssh "$NAS_SSH" "mkdir -p $NAS_DEPLOY_DIR/backups"
cat docker-compose.prod.yml | ssh "$NAS_SSH" "cat > $NAS_DEPLOY_DIR/compose.yaml"

echo "==> Pulling and starting on the NAS"
ssh "$NAS_SSH" \
    "$NAS_PATH_EXPORT && cd $NAS_DEPLOY_DIR && docker compose pull && docker compose up -d"

echo "==> Applying database migrations"
ssh "$NAS_SSH" \
    "$NAS_PATH_EXPORT && cd $NAS_DEPLOY_DIR && docker compose exec -T api alembic upgrade head"

echo "==> Deployed $IMAGE:$VERSION"
echo "    Local (NAS): http://127.0.0.1:8087/health"
echo "    Configure Web Station to reverse-proxy https://countscore.ombivince.synology.me -> http://localhost:8087"
