#!/usr/bin/env bash
# start.sh — Start Floci local GCP emulators (GCS + Pub/Sub)
# Supports Docker and Podman. Reads runtime from scripts/.runtime (set by install.sh).
# Usage:
#   bash gcp/scripts/start.sh              # use saved runtime
#   bash gcp/scripts/start.sh --docker     # force Docker
#   bash gcp/scripts/start.sh --podman     # force Podman
#   bash gcp/scripts/start.sh --gcs-only   # start GCS emulator only
#   bash gcp/scripts/start.sh --pubsub-only  # start Pub/Sub emulator only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Load saved runtime, allow flag override ────────────────────────────────────
RUNTIME=""
START_GCS=true
START_PUBSUB=true

[[ -f "${SCRIPT_DIR}/.runtime" ]] && source "${SCRIPT_DIR}/.runtime" && RUNTIME="${FLOCI_RUNTIME:-}"

for arg in "$@"; do
  case "$arg" in
    --docker)       RUNTIME="docker" ;;
    --podman)       RUNTIME="podman" ;;
    --gcs-only)     START_PUBSUB=false ;;
    --pubsub-only)  START_GCS=false ;;
  esac
done

[[ -z "$RUNTIME" ]] && RUNTIME="docker"

# ── Verify runtime is available ────────────────────────────────────────────────
if ! command -v "${RUNTIME}" &>/dev/null; then
  error "'${RUNTIME}' is not installed. Run: bash gcp/scripts/install.sh --${RUNTIME}"
fi

# ── Podman: ensure machine is running ─────────────────────────────────────────
if [[ "$RUNTIME" == "podman" ]]; then
  if ! podman machine list 2>/dev/null | grep -q "Currently running"; then
    info "Starting Podman machine..."
    podman machine start
  fi
fi

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# GCS emulator (fake-gcs-server)
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$START_GCS" == "true" ]]; then
  if "${RUNTIME}" ps --filter "name=floci-gcs" --filter "status=running" --format "{{.Names}}" 2>/dev/null | grep -q "^floci-gcs$"; then
    success "GCS emulator is already running."
  else
    "${RUNTIME}" rm -f floci-gcs 2>/dev/null || true

    GCS_ARGS=(
      "run" "-d"
      "--name" "floci-gcs"
      "-p" "4443:4443"
      "-v" "floci-gcs-data:/data"
    )
    [[ "$RUNTIME" == "podman" ]] && GCS_ARGS+=("--security-opt" "label=disable")
    GCS_ARGS+=(
      "fsouza/fake-gcs-server:latest"
      "-scheme" "http"
      "-port" "4443"
      "-public-host" "localhost"
    )

    info "Starting GCS emulator (runtime: ${RUNTIME})..."
    "${RUNTIME}" "${GCS_ARGS[@]}"

    echo -n "  Waiting for GCS emulator"
    for i in $(seq 1 20); do
      sleep 1
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        "http://localhost:4443/storage/v1/b" 2>/dev/null || echo "000")
      if [[ "$STATUS" == "200" ]]; then
        echo ""; success "GCS emulator ready in ~${i}s."; break
      fi
      echo -n "."
      if [[ $i -eq 20 ]]; then
        echo ""; warn "GCS health check timed out. Check: ${RUNTIME} logs floci-gcs"
      fi
    done
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# Pub/Sub emulator
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$START_PUBSUB" == "true" ]]; then
  if "${RUNTIME}" ps --filter "name=floci-pubsub" --filter "status=running" --format "{{.Names}}" 2>/dev/null | grep -q "^floci-pubsub$"; then
    success "Pub/Sub emulator is already running."
  else
    "${RUNTIME}" rm -f floci-pubsub 2>/dev/null || true

    PUBSUB_ARGS=(
      "run" "-d"
      "--name" "floci-pubsub"
      "-p" "8085:8085"
    )
    [[ "$RUNTIME" == "podman" ]] && PUBSUB_ARGS+=("--security-opt" "label=disable")
    PUBSUB_ARGS+=(
      "gcr.io/google.com/cloudsdktool/google-cloud-cli:emulators"
      "gcloud" "beta" "emulators" "pubsub" "start"
      "--host-port=0.0.0.0:8085"
      "--project=floci-project"
    )

    info "Starting Pub/Sub emulator (runtime: ${RUNTIME})..."
    "${RUNTIME}" "${PUBSUB_ARGS[@]}"

    echo -n "  Waiting for Pub/Sub emulator"
    for i in $(seq 1 30); do
      sleep 1
      if "${RUNTIME}" exec floci-pubsub nc -z localhost 8085 2>/dev/null; then
        echo ""; success "Pub/Sub emulator ready in ~${i}s."; break
      fi
      echo -n "."
      if [[ $i -eq 30 ]]; then
        echo ""; warn "Pub/Sub health check timed out. Check: ${RUNTIME} logs floci-pubsub"
      fi
    done
  fi
fi

echo ""
echo -e "${GREEN}✔  GCP emulators are running${NC}"
echo ""
[[ "$START_GCS"    == "true" ]] && echo "  GCS endpoint   : http://localhost:4443"
[[ "$START_PUBSUB" == "true" ]] && echo "  Pub/Sub host   : localhost:8085"
echo ""
echo "  Export env vars (or add to your shell profile):"
echo '    eval $(bash gcp/scripts/env.sh)'
echo ""
echo "  View logs:"
[[ "$START_GCS"    == "true" ]] && echo "    ${RUNTIME} logs -f floci-gcs"
[[ "$START_PUBSUB" == "true" ]] && echo "    ${RUNTIME} logs -f floci-pubsub"
echo "  Stop:"
echo "    bash gcp/scripts/stop.sh"
echo ""
