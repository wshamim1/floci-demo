#!/usr/bin/env bash
# teardown.sh — Stop and optionally purge all Floci state.
# Usage:
#   bash aws/scripts/teardown.sh           # stop container only (data kept)
#   bash aws/scripts/teardown.sh --purge   # stop + delete volume + remove image

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }

RUNTIME=""
PURGE=false

[[ -f "${SCRIPT_DIR}/.runtime" ]] && source "${SCRIPT_DIR}/.runtime" && RUNTIME="${FLOCI_RUNTIME:-}"

for arg in "$@"; do
  case "$arg" in
    --docker) RUNTIME="docker" ;;
    --podman) RUNTIME="podman" ;;
    --purge)  PURGE=true ;;
  esac
done

[[ -z "$RUNTIME" ]] && RUNTIME="docker"

if ! command -v "${RUNTIME}" &>/dev/null; then
  warn "'${RUNTIME}' not found — nothing to tear down."
  exit 0
fi

# ── Stop container ─────────────────────────────────────────────────────────────
info "Stopping Floci container..."
"${RUNTIME}" stop floci 2>/dev/null && success "Container stopped." || warn "Container was not running."

info "Removing Floci container..."
"${RUNTIME}" rm -f floci 2>/dev/null && success "Container removed." || warn "Container not found."

# ── Purge volume + image ───────────────────────────────────────────────────────
if [[ "$PURGE" == "true" ]]; then
  echo ""
  warn "Purge mode: this will DELETE all Floci data permanently."
  read -rp "  Are you sure? (yes/N): " confirm
  if [[ "${confirm}" != "yes" ]]; then
    warn "Aborted. No data was deleted."
    exit 0
  fi

  info "Removing 'floci-data' volume..."
  "${RUNTIME}" volume rm floci-data 2>/dev/null && success "Volume removed." || warn "Volume not found."

  info "Removing floci/floci:latest image..."
  "${RUNTIME}" rmi floci/floci:latest 2>/dev/null && success "Image removed." || warn "Image not found."

  # Remove saved runtime file
  rm -f "${SCRIPT_DIR}/.runtime"

  echo ""
  echo -e "${RED}✔  Floci fully purged. Re-run install.sh to start fresh.${NC}"
else
  echo ""
  success "Floci stopped. Data is preserved."
  echo "  To restart:       bash aws/scripts/start.sh"
  echo "  To purge all:     bash aws/scripts/teardown.sh --purge"
fi
echo ""
