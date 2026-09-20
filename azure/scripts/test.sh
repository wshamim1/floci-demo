#!/usr/bin/env bash
# test.sh — Smoke-test Azurite: Blob Storage, Queue Storage, Table Storage
# Requires: az CLI (Azure CLI)
# Usage:
#   bash azure/scripts/test.sh

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS=0; FAIL=0

info()    { echo -e "${CYAN}[TEST]${NC}  $*"; }
ok()      { echo -e "${GREEN}[PASS]${NC}  $*"; PASS=$((PASS + 1)); }
fail()    { echo -e "${RED}[FAIL]${NC}  $*"; FAIL=$((FAIL + 1)); }
warn()    { echo -e "${YELLOW}[SKIP]${NC}  $*"; }

ACCOUNT_NAME="devstoreaccount1"
ACCOUNT_KEY="Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=="
BLOB_ENDPOINT="http://127.0.0.1:10000/${ACCOUNT_NAME}"
QUEUE_ENDPOINT="http://127.0.0.1:10001/${ACCOUNT_NAME}"
TABLE_ENDPOINT="http://127.0.0.1:10002/${ACCOUNT_NAME}"
CONTAINER="floci-smoke-$$"
QUEUE_NAME="floci-smoke-queue-$$"
TABLE_NAME="flocismoke$$"   # Table names must be alphanumeric only
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Floci Azure Smoke Tests             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

if ! command -v az &>/dev/null; then
  echo -e "${RED}Azure CLI (az) is not installed. Run: bash azure/scripts/install.sh${NC}"
  exit 1
fi

# ── Connectivity ───────────────────────────────────────────────────────────────
info "Checking Azurite Blob endpoint..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BLOB_ENDPOINT}" 2>/dev/null || echo "000")
# Azurite returns 400 on a bare GET — that means it is up
if [[ "$STATUS" == "400" || "$STATUS" == "200" ]]; then
  ok "Azurite Blob endpoint reachable (HTTP ${STATUS})"
else
  fail "Cannot reach Azurite at ${BLOB_ENDPOINT}. Is it running? (bash azure/scripts/start.sh)"
  echo ""
  echo -e "${RED}Aborting — Azurite is not reachable.${NC}"
  exit 1
fi

# ══════════════════════════════════════════════════════════════════════════════
# Blob Storage Tests
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "── Blob Storage ──────────────────────────────────────────────────────────"

info "Creating container: ${CONTAINER}..."
if az storage container create \
    --name "${CONTAINER}" \
    --account-name "${ACCOUNT_NAME}" \
    --account-key "${ACCOUNT_KEY}" \
    --blob-endpoint "${BLOB_ENDPOINT}" \
    --output none 2>/dev/null; then
  ok "Container created: ${CONTAINER}"
else
  fail "Failed to create container"
fi

info "Uploading blob..."
echo "Hello from Floci Azure smoke test!" > "${TMP_DIR}/hello.txt"
if az storage blob upload \
    --container-name "${CONTAINER}" \
    --name "hello.txt" \
    --file "${TMP_DIR}/hello.txt" \
    --account-name "${ACCOUNT_NAME}" \
    --account-key "${ACCOUNT_KEY}" \
    --blob-endpoint "${BLOB_ENDPOINT}" \
    --output none 2>/dev/null; then
  ok "Blob uploaded: hello.txt"
else
  fail "Failed to upload blob"
fi

info "Downloading blob..."
if az storage blob download \
    --container-name "${CONTAINER}" \
    --name "hello.txt" \
    --file "${TMP_DIR}/hello-back.txt" \
    --account-name "${ACCOUNT_NAME}" \
    --account-key "${ACCOUNT_KEY}" \
    --blob-endpoint "${BLOB_ENDPOINT}" \
    --output none 2>/dev/null; then
  CONTENT=$(cat "${TMP_DIR}/hello-back.txt")
  if [[ "$CONTENT" == *"Hello from Floci Azure"* ]]; then
    ok "Blob downloaded and content verified."
  else
    fail "Blob content mismatch: '${CONTENT}'"
  fi
else
  fail "Failed to download blob"
fi

info "Listing blobs in container..."
COUNT=$(az storage blob list \
    --container-name "${CONTAINER}" \
    --account-name "${ACCOUNT_NAME}" \
    --account-key "${ACCOUNT_KEY}" \
    --blob-endpoint "${BLOB_ENDPOINT}" \
    --output tsv 2>/dev/null | wc -l | tr -d ' ')
if [[ "$COUNT" -ge 1 ]]; then
  ok "Blob listing returned ${COUNT} blob(s)."
else
  fail "Blob listing returned 0 blobs."
fi

info "Deleting blob..."
az storage blob delete \
    --container-name "${CONTAINER}" \
    --name "hello.txt" \
    --account-name "${ACCOUNT_NAME}" \
    --account-key "${ACCOUNT_KEY}" \
    --blob-endpoint "${BLOB_ENDPOINT}" \
    --output none 2>/dev/null && ok "Blob deleted." || fail "Failed to delete blob."

info "Deleting container..."
az storage container delete \
    --name "${CONTAINER}" \
    --account-name "${ACCOUNT_NAME}" \
    --account-key "${ACCOUNT_KEY}" \
    --blob-endpoint "${BLOB_ENDPOINT}" \
    --output none 2>/dev/null && ok "Container deleted." || fail "Failed to delete container."

# ══════════════════════════════════════════════════════════════════════════════
# Queue Storage Tests
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "── Queue Storage ─────────────────────────────────────────────────────────"

info "Creating queue: ${QUEUE_NAME}..."
if az storage queue create \
    --name "${QUEUE_NAME}" \
    --account-name "${ACCOUNT_NAME}" \
    --account-key "${ACCOUNT_KEY}" \
    --queue-endpoint "${QUEUE_ENDPOINT}" \
    --output none 2>/dev/null; then
  ok "Queue created: ${QUEUE_NAME}"
else
  fail "Failed to create queue"
fi

info "Sending message..."
if az storage message put \
    --queue-name "${QUEUE_NAME}" \
    --content "Floci Azure Queue smoke test" \
    --account-name "${ACCOUNT_NAME}" \
    --account-key "${ACCOUNT_KEY}" \
    --queue-endpoint "${QUEUE_ENDPOINT}" \
    --output none 2>/dev/null; then
  ok "Message sent."
else
  fail "Failed to send message"
fi

info "Receiving message..."
MSG=$(az storage message peek \
    --queue-name "${QUEUE_NAME}" \
    --account-name "${ACCOUNT_NAME}" \
    --account-key "${ACCOUNT_KEY}" \
    --queue-endpoint "${QUEUE_ENDPOINT}" \
    --query '[0].content' --output tsv 2>/dev/null || echo "")
if [[ "$MSG" == *"Floci Azure Queue smoke test"* ]]; then
  ok "Message received and content verified."
else
  fail "Message content mismatch or empty: '${MSG}'"
fi

info "Deleting queue..."
az storage queue delete \
    --name "${QUEUE_NAME}" \
    --account-name "${ACCOUNT_NAME}" \
    --account-key "${ACCOUNT_KEY}" \
    --queue-endpoint "${QUEUE_ENDPOINT}" \
    --output none 2>/dev/null && ok "Queue deleted." || fail "Failed to delete queue."

# ══════════════════════════════════════════════════════════════════════════════
# Table Storage Tests
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "── Table Storage ─────────────────────────────────────────────────────────"

info "Creating table: ${TABLE_NAME}..."
if az storage table create \
    --name "${TABLE_NAME}" \
    --account-name "${ACCOUNT_NAME}" \
    --account-key "${ACCOUNT_KEY}" \
    --table-endpoint "${TABLE_ENDPOINT}" \
    --output none 2>/dev/null; then
  ok "Table created: ${TABLE_NAME}"
else
  fail "Failed to create table"
fi

info "Inserting entity..."
if az storage entity insert \
    --table-name "${TABLE_NAME}" \
    --entity PartitionKey=smoke RowKey=1 message="Hello from Floci" \
    --account-name "${ACCOUNT_NAME}" \
    --account-key "${ACCOUNT_KEY}" \
    --table-endpoint "${TABLE_ENDPOINT}" \
    --output none 2>/dev/null; then
  ok "Entity inserted."
else
  fail "Failed to insert entity"
fi

info "Querying entity..."
VAL=$(az storage entity show \
    --table-name "${TABLE_NAME}" \
    --partition-key smoke \
    --row-key 1 \
    --account-name "${ACCOUNT_NAME}" \
    --account-key "${ACCOUNT_KEY}" \
    --table-endpoint "${TABLE_ENDPOINT}" \
    --query 'message' --output tsv 2>/dev/null || echo "")
if [[ "$VAL" == *"Hello from Floci"* ]]; then
  ok "Entity retrieved and content verified."
else
  fail "Entity content mismatch or empty: '${VAL}'"
fi

info "Deleting table..."
az storage table delete \
    --name "${TABLE_NAME}" \
    --account-name "${ACCOUNT_NAME}" \
    --account-key "${ACCOUNT_KEY}" \
    --table-endpoint "${TABLE_ENDPOINT}" \
    --output none 2>/dev/null && ok "Table deleted." || fail "Failed to delete table."

# ══════════════════════════════════════════════════════════════════════════════
# Summary
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "────────────────────────────────────────────────────────────────────────"
TOTAL=$((PASS + FAIL))
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}✔  All ${TOTAL} tests passed.${NC}"
else
  echo -e "${RED}✘  ${FAIL} of ${TOTAL} tests FAILED.${NC}"
  echo ""
  echo "  Troubleshooting:"
  echo "    docker logs floci-azure"
  echo "    bash azure/scripts/stop.sh && bash azure/scripts/start.sh"
  exit 1
fi
echo ""
