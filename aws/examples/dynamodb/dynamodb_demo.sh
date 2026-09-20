#!/usr/bin/env bash
# =============================================================================
# examples/dynamodb/dynamodb_demo.sh
#
# Demonstrates core DynamoDB operations against Floci:
#   - Create table
#   - List tables
#   - Put (insert) items
#   - Get (retrieve) items
#   - Scan table
#   - Delete table (cleanup)
#
# Prerequisites:
#   export AWS_ENDPOINT_URL=http://localhost:4566
#   export AWS_ACCESS_KEY_ID=test
#   export AWS_SECRET_ACCESS_KEY=test
#   export AWS_DEFAULT_REGION=us-east-1
# =============================================================================

set -euo pipefail

ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:4566}"
TABLE_NAME="my-floci-users"

echo "=== Floci DynamoDB Demo ==="
echo "Endpoint   : $ENDPOINT"
echo "Table Name : $TABLE_NAME"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 1. Create DynamoDB Table
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Creating DynamoDB Table ---"
aws dynamodb create-table \
  --table-name "$TABLE_NAME" \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --endpoint-url="$ENDPOINT"
echo "Table creation initiated."
echo ""

# Wait a brief moment to make sure local metadata is settled (usually instant in Floci)
sleep 1

# ──────────────────────────────────────────────────────────────────────────────
# 2. List Tables
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Listing Tables ---"
aws dynamodb list-tables --endpoint-url="$ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 3. Put Items (Insert)
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Inserting (Putting) Items ---"
echo "Inserting Alice..."
aws dynamodb put-item \
  --table-name "$TABLE_NAME" \
  --item '{"id": {"S": "u1"}, "name": {"S": "Alice"}, "role": {"S": "Admin"}}' \
  --endpoint-url="$ENDPOINT"

echo "Inserting Bob..."
aws dynamodb put-item \
  --table-name "$TABLE_NAME" \
  --item '{"id": {"S": "u2"}, "name": {"S": "Bob"}, "role": {"S": "Developer"}}' \
  --endpoint-url="$ENDPOINT"

echo "Items inserted successfully."
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 4. Get Item (Retrieve)
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Retrieving Item (id = u1) ---"
aws dynamodb get-item \
  --table-name "$TABLE_NAME" \
  --key '{"id": {"S": "u1"}}' \
  --endpoint-url="$ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 5. Scan Table (List All Items)
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Scanning Table (All Items) ---"
aws dynamodb scan \
  --table-name "$TABLE_NAME" \
  --endpoint-url="$ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 6. Delete Table (Cleanup)
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Deleting Table (Cleanup) ---"
aws dynamodb delete-table \
  --table-name "$TABLE_NAME" \
  --endpoint-url="$ENDPOINT"
echo "Table deleted."
echo ""

echo "=== DynamoDB demo complete ==="
