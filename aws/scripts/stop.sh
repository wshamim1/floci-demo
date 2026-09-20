#!/usr/bin/env bash
# stop.sh — Stop the Floci container (data is preserved in the volume).
# Usage:
#   bash aws/scripts/stop.sh              # use saved runtime
#   bash aws/scripts/stop.sh --docker
#   bash aws/scripts/stop.sh --podman

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

if "${RUNTIME}" ps --filter "name=floci" --filter "status=running" --format "{{.Names}}" 2>/dev/null | grep -q "^floci$"; then
  info "Stopping Floci container (${RUNTIME})..."
  "${RUNTIME}" stop floci
  success "Floci stopped. Data is preserved in the 'floci-data' volume."
else
  warn "Floci container is not running."
fi

echo ""
echo "  To restart:  bash aws/scripts/start.sh"
echo "  To purge:    bash aws/scripts/teardown.sh --purge"
echo ""
