#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-amansinhaatnycu/osp-week14-security-exercise:latest}"
FALLBACK_IMAGE="${FALLBACK_IMAGE:-osp-week15-rtl-fallback:latest}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker command not found on host."
  exit 1
fi

echo "Mounting: ${ROOT} -> /workspace"
echo "Trying Docker image: ${IMAGE}"

if docker pull "${IMAGE}"; then
  RUN_IMAGE="${IMAGE}"
else
  echo "WARNING: Could not pull ${IMAGE}. Building fallback image ${FALLBACK_IMAGE}."
  docker build -t "${FALLBACK_IMAGE}" -f "${ROOT}/docker/Dockerfile.fallback" "${ROOT}/docker"
  RUN_IMAGE="${FALLBACK_IMAGE}"
fi

docker run --rm -it \
  -v "${ROOT}:/workspace" \
  -w /workspace \
  "${RUN_IMAGE}" bash
