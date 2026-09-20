#!/usr/bin/env bash
# start.sh — Start Floci local AWS emulator
# Supports Docker and Podman. Reads runtime from scripts/.runtime (set by install.sh).
# Usage:
#   bash aws/scripts/start.sh              # use saved runtime
#   bash aws/scripts/start.sh --docker     # force Docker
#   bash aws/scripts/start.sh --podman     # force Podman
#   bash aws/scripts/start.sh --persist ./data   # custom data dir

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

[[ -z "$RUNTIME" ]] && RUNTIME="docker"   # sensible default

# ── Verify runtime is available ────────────────────────────────────────────────
if ! command -v "${RUNTIME}" &>/dev/null; then
  error "'${RUNTIME}' is not installed. Run: bash aws/scripts/install.sh --${RUNTIME}"
fi

# ── Podman: ensure machine is running ─────────────────────────────────────────
if [[ "$RUNTIME" == "podman" ]]; then
  if ! podman machine list 2>/dev/null | grep -q "Currently running"; then
    info "Starting Podman machine..."
    podman machine start
  fi

  # Prefer /var/run/docker.sock when Podman Desktop has created the compat symlink.
  # Fall back to the path reported by `podman machine inspect`, then a known default.
  if [[ -e "/var/run/docker.sock" ]]; then
    SOCKET_PATH="/var/run/docker.sock"
  else
    SOCKET_PATH="$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null || true)"
    if [[ -z "$SOCKET_PATH" ]] || [[ ! -S "$SOCKET_PATH" ]]; then
      SOCKET_PATH="${HOME}/.local/share/containers/podman/machine/podman.sock"
    fi
  fi

  # The socket is owned by the current user (mode 0600).
  # Floci's JVM runs as root inside the container; after UID remapping by
  # Podman the socket appears as root:nobody (0600) — unreadable by root.
  # chmod 777 on the host socket makes it accessible inside the container.
  if [[ -S "$SOCKET_PATH" ]]; then
    chmod 777 "$SOCKET_PATH"
  fi

  info "Using Podman socket: ${SOCKET_PATH}"
else
  SOCKET_PATH="/var/run/docker.sock"
fi

# ── Already running? ───────────────────────────────────────────────────────────
if "${RUNTIME}" ps --filter "name=floci" --filter "status=running" --format "{{.Names}}" 2>/dev/null | grep -q "^floci$"; then
  success "Floci is already running."
  echo ""
  echo "  Endpoint : http://localhost:4566"
  echo "  Runtime  : ${RUNTIME}"
  echo ""
  echo "  To set env vars:"
  echo '    export AWS_ENDPOINT_URL=http://localhost:4566'
  echo '    export AWS_ACCESS_KEY_ID=test'
  echo '    export AWS_SECRET_ACCESS_KEY=test'
  echo '    export AWS_DEFAULT_REGION=us-east-1'
  exit 0
fi

# ── Remove stale stopped container if present ─────────────────────────────────
"${RUNTIME}" rm -f floci 2>/dev/null || true

# ── Build run command ─────────────────────────────────────────────────────────
RUN_ARGS=(
  "run" "-d"
  "--name" "floci"
  "-p" "4566:4566"
  "-v" "${SOCKET_PATH}:/var/run/docker.sock"
  "-e" "FLOCI_STORAGE_MODE=hybrid"
  "-e" "FLOCI_LOG_LEVEL=info"
)

# Podman on macOS applies label security to bind-mounts even without SELinux.
# --security-opt label=disable lets the container open the socket fd.
if [[ "$RUNTIME" == "podman" ]]; then
  RUN_ARGS+=("--security-opt" "label=disable")
fi

if [[ -n "$DATA_DIR" ]]; then
  mkdir -p "$DATA_DIR"
  DATA_DIR="$(cd "$DATA_DIR" && pwd)"
  RUN_ARGS+=("-v" "${DATA_DIR}:/app/data")
  info "Persistent storage: ${DATA_DIR}"
else
  # Named volume — survives container restarts but not `teardown.sh --purge`
  RUN_ARGS+=("-v" "floci-data:/app/data")
  info "Using named volume 'floci-data' for persistence."
fi

RUN_ARGS+=("floci/floci:latest")

# ── Start ──────────────────────────────────────────────────────────────────────
echo ""
info "Starting Floci (runtime: ${RUNTIME})..."
"${RUNTIME}" "${RUN_ARGS[@]}"

# ── Health check ───────────────────────────────────────────────────────────────
echo -n "  Waiting for Floci to be ready"
for i in $(seq 1 20); do
  sleep 1
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4566/_floci/health 2>/dev/null || echo "000")
  if [[ "$STATUS" == "200" ]]; then
    echo ""
    success "Floci is ready in ~${i}s."
    break
  fi
  echo -n "."
  if [[ $i -eq 20 ]]; then
    echo ""
    warn "Health check timed out. Check logs: ${RUNTIME} logs floci"
  fi
done

echo ""
echo -e "${GREEN}✔  Floci is running on http://localhost:4566${NC}"
echo ""
echo "  Export these env vars (or add to your shell profile):"
echo ""
echo '    export AWS_ENDPOINT_URL=http://localhost:4566'
echo '    export AWS_ACCESS_KEY_ID=test'
echo '    export AWS_SECRET_ACCESS_KEY=test'
echo '    export AWS_DEFAULT_REGION=us-east-1'
echo ""
echo "  Quick one-liner:"
echo '    eval $(bash aws/scripts/env.sh)'
echo ""
echo "  View logs:  ${RUNTIME} logs -f floci"
echo "  Stop:       bash aws/scripts/stop.sh"
echo ""
