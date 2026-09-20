#!/usr/bin/env bash
# =============================================================================
# aws/scripts/stop-ui.sh
#
# Safely stops and removes the StackPort UI container.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }

RUNTIME=""
[[ -f "${SCRIPT_DIR}/.runtime" ]] && source "${SCRIPT_DIR}/.runtime" && RUNTIME="${FLOCI_RUNTIME:-}"
[[ -z "$RUNTIME" ]] && RUNTIME="docker"

info "Stopping StackPort UI container..."
"${RUNTIME}" stop floci-stackport 2>/dev/null && success "StackPort UI stopped." || warn "UI container was not running."

info "Removing StackPort UI container..."
"${RUNTIME}" rm -f floci-stackport 2>/dev/null && success "UI container removed." || warn "UI container not found."
echo ""
