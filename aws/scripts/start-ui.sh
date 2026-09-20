#!/usr/bin/env bash
# =============================================================================
# aws/scripts/start-ui.sh
#
# Starts the StackPort UI container (on port 8080) pointing to local Floci,
# and automatically opens your browser!
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

info "Stopping any stale StackPort UI container..."
"${RUNTIME}" stop floci-stackport 2>/dev/null || true
"${RUNTIME}" rm -f floci-stackport 2>/dev/null || true

# Set correct host endpoint resolver based on container runtime
HOST_ENDPOINT="host.docker.internal"
if [[ "$RUNTIME" == "podman" ]]; then
  HOST_ENDPOINT="host.containers.internal"
fi

info "Starting StackPort UI on http://localhost:8080 (runtime: ${RUNTIME})..."
"${RUNTIME}" run -d \
  --name floci-stackport \
  -p 8080:8080 \
  -e AWS_ENDPOINT_URL="http://${HOST_ENDPOINT}:4566" \
  -e AWS_ACCESS_KEY_ID="test" \
  -e AWS_SECRET_ACCESS_KEY="test" \
  -e AWS_DEFAULT_REGION="us-east-1" \
  davireis/stackport:latest >/dev/null

success "StackPort UI started successfully!"
echo ""
echo "👉 Open your browser at: http://localhost:8080"
echo ""

# Auto-open in default browser on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
  sleep 1
  open "http://localhost:8080"
fi
