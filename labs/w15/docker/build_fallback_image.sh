#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${IMAGE:-osp-week15-rtl-fallback:latest}"
docker build -t "${IMAGE}" -f "${ROOT}/docker/Dockerfile.fallback" "${ROOT}/docker"
echo "Built ${IMAGE}"
