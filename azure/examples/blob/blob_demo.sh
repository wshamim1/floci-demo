#!/usr/bin/env bash
# =============================================================================
# examples/blob/blob_demo.sh
#
# Demonstrates core Azure Blob Storage operations against Azurite:
#   - Create container
#   - Upload / download blobs
#   - List blobs
#   - Delete blob and container
#
# Prerequisites:
#   eval $(bash azure/scripts/env.sh)
#   # or manually:
#   export AZURE_STORAGE_ACCOUNT=devstoreaccount1
#   export AZURE_STORAGE_KEY=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==
#   export AZURE_BLOB_ENDPOINT=http://127.0.0.1:10000/devstoreaccount1
# =============================================================================

set -euo pipefail

ACCOUNT_NAME="${AZURE_STORAGE_ACCOUNT:-devstoreaccount1}"
ACCOUNT_KEY="${AZURE_STORAGE_KEY:-Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==}"
BLOB_ENDPOINT="${AZURE_BLOB_ENDPOINT:-http://127.0.0.1:10000/${ACCOUNT_NAME}}"
CONTAINER="my-floci-container"
LOCAL_FILE="/tmp/floci_blob_hello.txt"
DOWNLOAD_FILE="/tmp/floci_blob_downloaded.txt"

echo "=== Floci Azure Blob Storage Demo ==="
echo "Endpoint  : $BLOB_ENDPOINT"
echo "Container : $CONTAINER"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 1. Create container
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Creating container ---"
az storage container create \
  --name "$CONTAINER" \
  --account-name "$ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --blob-endpoint "$BLOB_ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 2. Upload a blob
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Uploading blob ---"
echo "Hello from Floci Azure!" > "$LOCAL_FILE"
az storage blob upload \
  --container-name "$CONTAINER" \
  --name "hello.txt" \
  --file "$LOCAL_FILE" \
  --account-name "$ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --blob-endpoint "$BLOB_ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 3. List blobs in the container
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Listing blobs ---"
az storage blob list \
  --container-name "$CONTAINER" \
  --account-name "$ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --blob-endpoint "$BLOB_ENDPOINT" \
  --output table
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 4. Download the blob
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Downloading blob ---"
az storage blob download \
  --container-name "$CONTAINER" \
  --name "hello.txt" \
  --file "$DOWNLOAD_FILE" \
  --account-name "$ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --blob-endpoint "$BLOB_ENDPOINT"
echo "File contents:"
cat "$DOWNLOAD_FILE"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 5. Cleanup
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Cleaning up ---"
az storage blob delete \
  --container-name "$CONTAINER" \
  --name "hello.txt" \
  --account-name "$ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --blob-endpoint "$BLOB_ENDPOINT"

az storage container delete \
  --name "$CONTAINER" \
  --account-name "$ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --blob-endpoint "$BLOB_ENDPOINT"

rm -f "$LOCAL_FILE" "$DOWNLOAD_FILE"
echo ""
echo "=== Blob Storage demo complete ==="
