#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "The old smoke check has been replaced by a real producer-consumer Gem5 run."
exec bash "$SCRIPT_DIR/run_producer_consumer.sh"
