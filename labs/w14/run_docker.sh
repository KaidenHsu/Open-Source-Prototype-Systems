#!/usr/bin/env bash
set -euo pipefail
IMAGE=${IMAGE:-osp-week14-security-exercise}
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  docker build -t "$IMAGE" .
fi
docker run --rm -it -v "$(PWD)":/work -w /work "$IMAGE" bash
