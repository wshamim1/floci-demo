#!/usr/bin/env bash
# stop.sh — Stop the Azurite container (data is preserved in the volume).
# Usage:
#   bash azure/scripts/stop.sh              # use saved runtime
#   bash azure/scripts/stop.sh --docker
#   bash azure/scripts/stop.sh --podman

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }

RUNTIME=""
[[ -f "${SCRIPT_DIR}/.runtime" ]] && source "${SCRIPT_DIR}/.runtime" && RUNTIME="${FLOCI_RUNTIME:-}"

for arg in "$@"; do
  case "$arg" in
    --docker) RUNTIME="docker" ;;
    --podman) RUNTIME="podman" ;;
  esac
done

[[ -z "$RUNTIME" ]] && RUNTIME="docker"

if ! command -v "${RUNTIME}" &>/dev/null; then
  warn "'${RUNTIME}' not found — nothing to stop."
  exit 0
fi

if "${RUNTIME}" ps --filter "name=floci-azure" --filter "status=running" --format "{{.Names}}" 2>/dev/null | grep -q "^floci-azure$"; then
  info "Stopping Azurite container (${RUNTIME})..."
  "${RUNTIME}" stop floci-azure
  success "Azurite stopped. Data is preserved in the 'floci-azure-data' volume."
else
  warn "Azurite container is not running."
fi

echo ""
echo "  To restart:  bash azure/scripts/start.sh"
echo "  To purge:    bash azure/scripts/teardown.sh --purge"
echo ""
