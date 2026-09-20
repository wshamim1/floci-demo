#!/usr/bin/env bash
# stop.sh — Stop the GCP emulator containers (data is preserved in volumes).
# Usage:
#   bash gcp/scripts/stop.sh              # stop all
#   bash gcp/scripts/stop.sh --docker
#   bash gcp/scripts/stop.sh --podman
#   bash gcp/scripts/stop.sh --gcs-only
#   bash gcp/scripts/stop.sh --pubsub-only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }

RUNTIME=""
STOP_GCS=true
STOP_PUBSUB=true

[[ -f "${SCRIPT_DIR}/.runtime" ]] && source "${SCRIPT_DIR}/.runtime" && RUNTIME="${FLOCI_RUNTIME:-}"

for arg in "$@"; do
  case "$arg" in
    --docker)       RUNTIME="docker" ;;
    --podman)       RUNTIME="podman" ;;
    --gcs-only)     STOP_PUBSUB=false ;;
    --pubsub-only)  STOP_GCS=false ;;
  esac
done

[[ -z "$RUNTIME" ]] && RUNTIME="docker"

if ! command -v "${RUNTIME}" &>/dev/null; then
  warn "'${RUNTIME}' not found — nothing to stop."
  exit 0
fi

if [[ "$STOP_GCS" == "true" ]]; then
  if "${RUNTIME}" ps --filter "name=floci-gcs" --filter "status=running" --format "{{.Names}}" 2>/dev/null | grep -q "^floci-gcs$"; then
    info "Stopping GCS emulator..."
    "${RUNTIME}" stop floci-gcs
    success "GCS emulator stopped."
  else
    warn "GCS emulator is not running."
  fi
fi

if [[ "$STOP_PUBSUB" == "true" ]]; then
  if "${RUNTIME}" ps --filter "name=floci-pubsub" --filter "status=running" --format "{{.Names}}" 2>/dev/null | grep -q "^floci-pubsub$"; then
    info "Stopping Pub/Sub emulator..."
    "${RUNTIME}" stop floci-pubsub
    success "Pub/Sub emulator stopped."
  else
    warn "Pub/Sub emulator is not running."
  fi
fi

echo ""
echo "  To restart:  bash gcp/scripts/start.sh"
echo "  To purge:    bash gcp/scripts/teardown.sh --purge"
echo ""
