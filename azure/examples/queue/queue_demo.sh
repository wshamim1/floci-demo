#!/usr/bin/env bash
# =============================================================================
# examples/queue/queue_demo.sh
#
# Demonstrates core Azure Queue Storage operations against Azurite:
#   - Create queue
#   - Send messages
#   - Peek / receive messages
#   - Delete queue
#
# Prerequisites:
#   eval $(bash azure/scripts/env.sh)
# =============================================================================

set -euo pipefail

ACCOUNT_NAME="${AZURE_STORAGE_ACCOUNT:-devstoreaccount1}"
ACCOUNT_KEY="${AZURE_STORAGE_KEY:-Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==}"
QUEUE_ENDPOINT="${AZURE_QUEUE_ENDPOINT:-http://127.0.0.1:10001/${ACCOUNT_NAME}}"
QUEUE_NAME="my-floci-queue"

echo "=== Floci Azure Queue Storage Demo ==="
echo "Endpoint : $QUEUE_ENDPOINT"
echo "Queue    : $QUEUE_NAME"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 1. Create queue
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Creating queue ---"
az storage queue create \
  --name "$QUEUE_NAME" \
  --account-name "$ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --queue-endpoint "$QUEUE_ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 2. Send messages
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Sending messages ---"
az storage message put \
  --queue-name "$QUEUE_NAME" \
  --content "Hello from Floci Azure! (message 1)" \
  --account-name "$ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --queue-endpoint "$QUEUE_ENDPOINT"

az storage message put \
  --queue-name "$QUEUE_NAME" \
  --content "Hello from Floci Azure! (message 2)" \
  --account-name "$ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --queue-endpoint "$QUEUE_ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 3. Peek at messages (non-destructive)
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Peeking messages ---"
az storage message peek \
  --queue-name "$QUEUE_NAME" \
  --num-messages 2 \
  --account-name "$ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --queue-endpoint "$QUEUE_ENDPOINT" \
  --output table
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 4. Receive (dequeue) messages
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Receiving messages ---"
az storage message get \
  --queue-name "$QUEUE_NAME" \
  --num-messages 2 \
  --account-name "$ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --queue-endpoint "$QUEUE_ENDPOINT" \
  --output table
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 5. Cleanup
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Deleting queue ---"
az storage queue delete \
  --name "$QUEUE_NAME" \
  --account-name "$ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --queue-endpoint "$QUEUE_ENDPOINT"
echo ""
echo "=== Queue Storage demo complete ==="
