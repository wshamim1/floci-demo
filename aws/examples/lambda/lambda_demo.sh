#!/usr/bin/env bash
# =============================================================================
# examples/lambda/lambda_demo.sh
#
# Demonstrates Lambda operations against Floci:
#   - Package the handler from src/index.js
#   - Create the Lambda function
#   - Invoke synchronously (RequestResponse)
#   - Invoke asynchronously (Event / fire-and-forget)
#   - List functions
#   - View captured log groups
#   - Delete the function
#
# Prerequisites:
#   export AWS_ENDPOINT_URL=http://localhost:4566
#   export AWS_ACCESS_KEY_ID=floci
#   export AWS_SECRET_ACCESS_KEY=floci
#   export AWS_DEFAULT_REGION=us-east-1
#
# Requires: zip, node (only for reference — execution happens inside Docker)
# =============================================================================

set -euo pipefail

ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:4566}"
FUNCTION_NAME="hello-floci"
HANDLER_DIR="$(cd "$(dirname "$0")/src" && pwd)"
ZIP_FILE="/tmp/floci_function.zip"
RESPONSE_FILE="/tmp/floci_response.json"

echo "=== Floci Lambda Demo ==="
echo "Endpoint : $ENDPOINT"
echo "Function : $FUNCTION_NAME"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 1. Package the function
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Packaging function ---"
(cd "$HANDLER_DIR" && zip -r "$ZIP_FILE" index.js)
echo "Created: $ZIP_FILE"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 2. Create the function in Floci
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Creating function ---"
aws lambda create-function \
  --function-name "$FUNCTION_NAME" \
  --runtime nodejs20.x \
  --role arn:aws:iam::000000000000:role/lambda-role \
  --handler index.handler \
  --zip-file "fileb://$ZIP_FILE" \
  --endpoint-url="$ENDPOINT"
# Expected:
# {
#     "FunctionName": "hello-floci",
#     "FunctionArn": "arn:aws:lambda:us-east-1:000000000000:function:hello-floci",
#     "Runtime": "nodejs20.x",
#     ...
# }
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 3. Invoke synchronously (RequestResponse — default)
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Invoking synchronously ---"
aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --payload '{"name": "DevOps Engineer"}' \
  --cli-binary-format raw-in-base64-out \
  "$RESPONSE_FILE" \
  --endpoint-url="$ENDPOINT"
# Expected:
# {
#     "StatusCode": 200,
#     "ExecutedVersion": "$LATEST"
# }

echo "Response payload:"
cat "$RESPONSE_FILE" | python3 -m json.tool 2>/dev/null || cat "$RESPONSE_FILE"
# Expected body: {"message": "Hello, DevOps Engineer! Lambda is running on Floci.", ...}
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 4. Invoke asynchronously (Event — fire and forget)
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Invoking asynchronously ---"
aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --invocation-type Event \
  --payload '{"name": "Async Call"}' \
  --cli-binary-format raw-in-base64-out \
  /dev/null \
  --endpoint-url="$ENDPOINT"
# Expected: { "StatusCode": 202 }
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 5. List all functions
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Listing functions ---"
aws lambda list-functions --endpoint-url="$ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 6. View CloudWatch log groups captured by Floci
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Log groups ---"
aws logs describe-log-groups --endpoint-url="$ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 7. Cleanup
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Deleting function ---"
aws lambda delete-function \
  --function-name "$FUNCTION_NAME" \
  --endpoint-url="$ENDPOINT"
echo "Function deleted."

rm -f "$ZIP_FILE" "$RESPONSE_FILE"
echo ""

echo "=== Lambda demo complete ==="
echo "Note: first invocation takes ~1-2 s (Docker cold start)."
echo "      Subsequent invocations are warm (sub-millisecond routing)."
