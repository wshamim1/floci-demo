#!/usr/bin/env bash
# =============================================================================
# examples/table/table_demo.sh
#
# Demonstrates core Azure Table Storage operations against Azurite:
#   - Create table
#   - Insert / query / update entities
#   - Delete table
#
# Prerequisites:
#   eval $(bash azure/scripts/env.sh)
# =============================================================================

set -euo pipefail

ACCOUNT_NAME="${AZURE_STORAGE_ACCOUNT:-devstoreaccount1}"
ACCOUNT_KEY="${AZURE_STORAGE_KEY:-Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==}"
TABLE_ENDPOINT="${AZURE_TABLE_ENDPOINT:-http://127.0.0.1:10002/${ACCOUNT_NAME}}"
TABLE_NAME="myflociusers"    # Table names: alphanumeric only, starts with letter

echo "=== Floci Azure Table Storage Demo ==="
echo "Endpoint : $TABLE_ENDPOINT"
echo "Table    : $TABLE_NAME"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 1. Create table
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Creating table ---"
az storage table create \
  --name "$TABLE_NAME" \
  --account-name "$ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --table-endpoint "$TABLE_ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 2. Insert entities
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Inserting entities ---"
az storage entity insert \
  --table-name "$TABLE_NAME" \
  --entity PartitionKey=users RowKey=1 name=Alice age=30 \
  --account-name "$ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --table-endpoint "$TABLE_ENDPOINT"

az storage entity insert \
  --table-name "$TABLE_NAME" \
  --entity PartitionKey=users RowKey=2 name=Bob age=25 \
  --account-name "$ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --table-endpoint "$TABLE_ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 3. Query a single entity
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Querying entity RowKey=1 ---"
az storage entity show \
  --table-name "$TABLE_NAME" \
  --partition-key users \
  --row-key 1 \
  --account-name "$ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --table-endpoint "$TABLE_ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 4. Query all entities in a partition
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Querying all entities in partition 'users' ---"
az storage entity query \
  --table-name "$TABLE_NAME" \
  --filter "PartitionKey eq 'users'" \
  --account-name "$ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --table-endpoint "$TABLE_ENDPOINT" \
  --output table
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 5. Cleanup
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Deleting table ---"
az storage table delete \
  --name "$TABLE_NAME" \
  --account-name "$ACCOUNT_NAME" \
  --account-key "$ACCOUNT_KEY" \
  --table-endpoint "$TABLE_ENDPOINT"
echo ""
echo "=== Table Storage demo complete ==="
