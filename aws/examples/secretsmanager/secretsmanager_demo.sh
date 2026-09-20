#!/usr/bin/env bash
# =============================================================================
# examples/secretsmanager/secretsmanager_demo.sh
#
# Demonstrates core Secrets Manager operations against Floci:
#   - Create a secret
#   - List secrets
#   - Get secret value
#   - Delete secret (cleanup)
#
# Prerequisites:
#   export AWS_ENDPOINT_URL=http://localhost:4566
#   export AWS_ACCESS_KEY_ID=test
#   export AWS_SECRET_ACCESS_KEY=test
#   export AWS_DEFAULT_REGION=us-east-1
# =============================================================================

set -euo pipefail

ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:4566}"
SECRET_NAME="my-floci-api-key"

echo "=== Floci Secrets Manager Demo ==="
echo "Endpoint    : $ENDPOINT"
echo "Secret Name : $SECRET_NAME"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 1. Create a Secret
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Creating Secret ---"
aws secretsmanager create-secret \
  --name "$SECRET_NAME" \
  --description "Local development API Key" \
  --secret-string '{"api_key": "floci_secret_token_12345", "username": "admin"}' \
  --endpoint-url="$ENDPOINT"
echo "Secret created successfully."
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 2. List Secrets
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Listing Secrets ---"
aws secretsmanager list-secrets --endpoint-url="$ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 3. Get Secret Value
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Getting Secret Value ---"
aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --endpoint-url="$ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 4. Delete Secret (Cleanup)
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Deleting Secret (Cleanup) ---"
aws secretsmanager delete-secret \
  --secret-id "$SECRET_NAME" \
  --force-delete-without-recovery \
  --endpoint-url="$ENDPOINT"
echo "Secret deleted."
echo ""

echo "=== Secrets Manager demo complete ==="
