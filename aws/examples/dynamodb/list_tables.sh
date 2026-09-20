#!/usr/bin/env bash
# =============================================================================
# examples/dynamodb/list_tables.sh
#
# Simple script to list DynamoDB tables against Floci.
#
# Prerequisites:
#   export AWS_ENDPOINT_URL=http://localhost:4566
#   export AWS_ACCESS_KEY_ID=test
#   export AWS_SECRET_ACCESS_KEY=test
#   export AWS_DEFAULT_REGION=us-east-1
# =============================================================================

set -euo pipefail

ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:4566}"

echo "=== Listing Floci DynamoDB Tables ==="
echo "Endpoint : $ENDPOINT"
echo ""

aws dynamodb list-tables --endpoint-url="$ENDPOINT"
echo ""
echo "=== Listing complete ==="
