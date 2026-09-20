#!/usr/bin/env bash
# teardown.sh — Stop and optionally purge all GCP emulator state.
# Usage:
#   bash gcp/scripts/teardown.sh           # stop containers only (data kept)
#   bash gcp/scripts/teardown.sh --purge   # stop + delete volumes + remove images

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

# ── Stop and remove containers ─────────────────────────────────────────────────
for CONTAINER in floci-gcs floci-pubsub; do
  info "Stopping ${CONTAINER}..."
  "${RUNTIME}" stop "${CONTAINER}" 2>/dev/null && success "${CONTAINER} stopped." || warn "${CONTAINER} was not running."
  info "Removing ${CONTAINER}..."
  "${RUNTIME}" rm -f "${CONTAINER}" 2>/dev/null && success "${CONTAINER} removed." || warn "${CONTAINER} not found."
done

# ── Purge volumes + images ─────────────────────────────────────────────────────
if [[ "$PURGE" == "true" ]]; then
  echo ""
  warn "Purge mode: this will DELETE all GCP emulator data permanently."
  read -rp "  Are you sure? (yes/N): " confirm
  if [[ "${confirm}" != "yes" ]]; then
    warn "Aborted. No data was deleted."
    exit 0
  fi

  info "Removing 'floci-gcs-data' volume..."
  "${RUNTIME}" volume rm floci-gcs-data 2>/dev/null && success "Volume removed." || warn "Volume not found."

  info "Removing GCS emulator image..."
  "${RUNTIME}" rmi fsouza/fake-gcs-server:latest 2>/dev/null && success "GCS image removed." || warn "GCS image not found."

  info "Removing Pub/Sub emulator image..."
  "${RUNTIME}" rmi gcr.io/google.com/cloudsdktool/google-cloud-cli:emulators 2>/dev/null \
    && success "Pub/Sub image removed." || warn "Pub/Sub image not found."

  rm -f "${SCRIPT_DIR}/.runtime"

  echo ""
  echo -e "${RED}✔  GCP emulators fully purged. Re-run install.sh to start fresh.${NC}"
else
  echo ""
  success "GCP emulators stopped. Data is preserved."
  echo "  To restart:       bash gcp/scripts/start.sh"
  echo "  To purge all:     bash gcp/scripts/teardown.sh --purge"
fi
echo ""
