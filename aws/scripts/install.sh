#!/usr/bin/env bash
# install.sh — Install all Floci dependencies on macOS (arm64 / x86_64)
# Supports Docker Desktop or Podman as the container runtime.
# Usage: bash aws/scripts/install.sh [--docker | --podman]

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Floci Installer — macOS           ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# ── Runtime selection ──────────────────────────────────────────────────────────
RUNTIME=""

# Accept --docker / --podman flag, or auto-detect, or prompt
for arg in "$@"; do
  case "$arg" in
    --docker) RUNTIME="docker" ;;
    --podman) RUNTIME="podman" ;;
  esac
done

if [[ -z "$RUNTIME" ]]; then
  # Auto-detect if one is already installed
  if command -v podman &>/dev/null && ! command -v docker &>/dev/null; then
    RUNTIME="podman"
    info "Podman detected — using Podman as the container runtime."
  elif command -v docker &>/dev/null && ! command -v podman &>/dev/null; then
    RUNTIME="docker"
    info "Docker detected — using Docker as the container runtime."
  else
    # Both present or neither — ask
    echo "Choose a container runtime:"
    echo "  1) Docker Desktop  (default, GUI app, rootful)"
    echo "  2) Podman          (daemonless, rootless, CLI-only)"
    read -rp "Enter 1 or 2 [1]: " choice
    case "${choice:-1}" in
      2) RUNTIME="podman" ;;
      *) RUNTIME="docker" ;;
    esac
  fi
fi

echo ""
info "Selected runtime: ${RUNTIME}"
# Persist the choice for other scripts to read
mkdir -p "$(dirname "$0")"
echo "FLOCI_RUNTIME=${RUNTIME}" > "$(dirname "$0")/.runtime"
echo ""

# ── 1. Homebrew ────────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  success "Homebrew already installed ($(brew --version | head -1))"
fi

# ── 2a. Docker Desktop ─────────────────────────────────────────────────────────
if [[ "$RUNTIME" == "docker" ]]; then
  if ! command -v docker &>/dev/null; then
    info "Installing Docker Desktop via Homebrew Cask..."
    brew install --cask docker
    echo ""
    warn "Docker Desktop installed. Open it manually to start the daemon:"
    warn "  open /Applications/Docker.app"
    warn "Wait until the whale icon in the menu bar stops animating, then re-run this script."
    exit 0
  else
    success "Docker already installed ($(docker --version))"
  fi

  # Verify Docker daemon is running
  if ! docker info &>/dev/null; then
    warn "Docker daemon is not running. Attempting to start Docker Desktop..."
    open /Applications/Docker.app 2>/dev/null || true
    echo -n "  Waiting for Docker daemon"
    for i in $(seq 1 30); do
      sleep 2
      if docker info &>/dev/null; then
        echo ""; success "Docker daemon is now running."; break
      fi
      echo -n "."
      if [[ $i -eq 30 ]]; then
        echo ""
        error "Docker did not start within 60 s. Open Docker Desktop manually and retry."
      fi
    done
  else
    success "Docker daemon is running."
  fi
fi

# ── 2b. Podman ─────────────────────────────────────────────────────────────────
if [[ "$RUNTIME" == "podman" ]]; then
  if ! command -v podman &>/dev/null; then
    info "Installing Podman via Homebrew..."
    brew install podman
  else
    success "Podman already installed ($(podman --version))"
  fi

  # Initialise and start the Podman machine if not already running
  if ! podman machine list 2>/dev/null | grep -q "Currently running"; then
    info "Initialising Podman machine (first-time setup)..."
    podman machine init 2>/dev/null || true
    info "Starting Podman machine..."
    podman machine start
    success "Podman machine is running."
  else
    success "Podman machine is already running."
  fi

  # podman-compose for docker-compose.yml support
  if ! command -v podman-compose &>/dev/null; then
    info "Installing podman-compose..."
    brew install podman-compose 2>/dev/null || pip3 install podman-compose --quiet
  else
    success "podman-compose already installed."
  fi
fi

# ── 3. AWS CLI ────────────────────────────────────────────────────────────────
if ! command -v aws &>/dev/null; then
  info "Installing AWS CLI..."
  brew install awscli
else
  success "AWS CLI already installed ($(aws --version 2>&1 | head -1))"
fi

# ── 4. Floci CLI ──────────────────────────────────────────────────────────────
if ! command -v floci &>/dev/null; then
  info "Installing Floci CLI via Homebrew..."
  brew install floci-io/floci/floci
else
  success "Floci CLI already installed ($(floci --version 2>/dev/null || echo 'version unknown'))"
fi

# ── 5. Pull the Floci Docker image ────────────────────────────────────────────
info "Pulling latest Floci image (floci/floci:latest) with ${RUNTIME}..."
"${RUNTIME}" pull floci/floci:latest
success "floci/floci:latest pulled."

echo ""
echo -e "${GREEN}✔  All dependencies installed successfully (runtime: ${RUNTIME}).${NC}"
echo ""
echo "  Next steps:"
echo "    bash aws/scripts/start.sh      # start Floci"
echo "    bash aws/scripts/test.sh       # run smoke tests"
echo ""
