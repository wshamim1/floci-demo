#!/usr/bin/env bash
# start.sh — Start Floci local Azure emulator (Azurite)
# Supports Docker and Podman. Reads runtime from scripts/.runtime (set by install.sh).
# Usage:
#   bash azure/scripts/start.sh              # use saved runtime
#   bash azure/scripts/start.sh --docker     # force Docker
#   bash azure/scripts/start.sh --podman     # force Podman
#   bash azure/scripts/start.sh --persist ./data   # custom data dir

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Load saved runtime, allow flag override ────────────────────────────────────
RUNTIME=""
DATA_DIR=""

[[ -f "${SCRIPT_DIR}/.runtime" ]] && source "${SCRIPT_DIR}/.runtime" && RUNTIME="${FLOCI_RUNTIME:-}"

for arg in "$@"; do
  case "$arg" in
    --docker)       RUNTIME="docker" ;;
    --podman)       RUNTIME="podman" ;;
    --persist=*)    DATA_DIR="${arg#*=}" ;;
    --persist)      shift; DATA_DIR="${1:-}" ;;
  esac
done

[[ -z "$RUNTIME" ]] && RUNTIME="docker"

# ── Verify runtime is available ────────────────────────────────────────────────
if ! command -v "${RUNTIME}" &>/dev/null; then
  error "'${RUNTIME}' is not installed. Run: bash azure/scripts/install.sh --${RUNTIME}"
fi

# ── Podman: ensure machine is running ─────────────────────────────────────────
if [[ "$RUNTIME" == "podman" ]]; then
  if ! podman machine list 2>/dev/null | grep -q "Currently running"; then
    info "Starting Podman machine..."
    podman machine start
  fi
fi

# ── Already running? ───────────────────────────────────────────────────────────
if "${RUNTIME}" ps --filter "name=floci-azure" --filter "status=running" --format "{{.Names}}" 2>/dev/null | grep -q "^floci-azure$"; then
  success "Floci Azure is already running."
  echo ""
  echo "  Consolidated endpoint : http://localhost:4577"
  echo "  Runtime               : ${RUNTIME}"
  echo ""
  echo "  To set env vars:"
  echo '    eval $(bash azure/scripts/env.sh)'
  exit 0
fi

# ── Remove stale stopped container if present ─────────────────────────────────
"${RUNTIME}" rm -f floci-azure 2>/dev/null || true

# ── Build run command ─────────────────────────────────────────────────────────
RUN_ARGS=(
  "run" "-d"
  "--name" "floci-azure"
  "-p" "4577:4577"
)

if [[ "$RUNTIME" == "podman" ]]; then
  RUN_ARGS+=("--security-opt" "label=disable")
  
  # Inject socket path for Podman environments
  if [[ -e "/var/run/docker.sock" ]]; then
    SOCKET_PATH="/var/run/docker.sock"
  else
    SOCKET_PATH="$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null || true)"
    if [[ -z "$SOCKET_PATH" ]] || [[ ! -S "$SOCKET_PATH" ]]; then
      SOCKET_PATH="${HOME}/.local/share/containers/podman/machine/podman.sock"
    fi
  fi
  if [[ -S "$SOCKET_PATH" ]]; then
    chmod 777 "$SOCKET_PATH"
  fi
  RUN_ARGS+=("-v" "${SOCKET_PATH}:/var/run/docker.sock")
else
  RUN_ARGS+=("-v" "/var/run/docker.sock:/var/run/docker.sock")
fi

if [[ -n "$DATA_DIR" ]]; then
  mkdir -p "$DATA_DIR"
  DATA_DIR="$(cd "$DATA_DIR" && pwd)"
  RUN_ARGS+=("-v" "${DATA_DIR}:/app/data")
  info "Persistent storage: ${DATA_DIR}"
else
  RUN_ARGS+=("-v" "floci-azure-data:/app/data")
  info "Using named volume 'floci-azure-data' for persistence."
fi

RUN_ARGS+=(
  "-e" "FLOCI_AZ_STORAGE_MODE=hybrid"
  "-e" "FLOCI_AZ_STORAGE_PATH=/app/data"
  "floci/floci-az:latest"
)

# ── Start ──────────────────────────────────────────────────────────────────────
echo ""
info "Starting Floci Azure (runtime: ${RUNTIME})..."
"${RUNTIME}" "${RUN_ARGS[@]}"

# ── Health check ───────────────────────────────────────────────────────────────
echo -n "  Waiting for Floci Azure to be ready"
for i in $(seq 1 20); do
  sleep 1
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    "http://localhost:4577/_floci/health" 2>/dev/null || echo "000")
  if [[ "$STATUS" == "200" ]]; then
    echo ""
    success "Floci Azure is ready in ~${i}s."
    break
  fi
  echo -n "."
  if [[ $i -eq 20 ]]; then
    echo ""
    warn "Health check timed out. Check logs: ${RUNTIME} logs floci-azure"
  fi
done

echo ""
echo -e "${GREEN}✔  Floci Azure is running${NC}"
echo ""
echo "  Consolidated endpoint : http://localhost:4577"
echo ""
echo "  Export env vars (or add to your shell profile):"
echo '    eval $(bash azure/scripts/env.sh)'
echo ""
echo "  View logs:  ${RUNTIME} logs -f floci-azure"
echo "  Stop:       bash azure/scripts/stop.sh"
echo ""
