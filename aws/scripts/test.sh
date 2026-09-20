#!/usr/bin/env bash
# test.sh — Smoke-test Floci: S3, SQS, Lambda (Node.js)
# Requires: aws CLI, curl, zip, node (for Lambda package)
# Usage:
#   bash aws/scripts/test.sh
#   bash aws/scripts/test.sh --skip-lambda   # skip Lambda (no docker.sock / node)

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS=0; FAIL=0

info()    { echo -e "${CYAN}[TEST]${NC}  $*"; }
ok()      { echo -e "${GREEN}[PASS]${NC}  $*"; PASS=$((PASS + 1)); }
fail()    { echo -e "${RED}[FAIL]${NC}  $*"; FAIL=$((FAIL + 1)); }
warn()    { echo -e "${YELLOW}[SKIP]${NC}  $*"; }

SKIP_LAMBDA=false
for arg in "$@"; do
  [[ "$arg" == "--skip-lambda" ]] && SKIP_LAMBDA=true
done

export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_PROFILE=floci

ENDPOINT="http://localhost:4566"
BUCKET="floci-smoke-test-$$"
QUEUE="floci-smoke-queue-$$"
LAMBDA_NAME="floci-smoke-fn-$$"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Floci Smoke Tests                 ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# ── Connectivity ───────────────────────────────────────────────────────────────
info "Checking Floci endpoint..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${ENDPOINT}/_floci/health" 2>/dev/null || echo "000")
if [[ "$STATUS" == "200" ]]; then
  ok "Floci health endpoint reachable (HTTP ${STATUS})"
else
  # Some versions return 404 on /_floci/health but still work — try S3 list
  STATUS2=$(curl -s -o /dev/null -w "%{http_code}" "${ENDPOINT}/" 2>/dev/null || echo "000")
  if [[ "$STATUS2" =~ ^[2-4] ]]; then
    ok "Floci endpoint reachable (HTTP ${STATUS2})"
  else
    fail "Cannot reach Floci at ${ENDPOINT}. Is it running? (bash aws/scripts/start.sh)"
    echo ""
    echo -e "${RED}Aborting — Floci is not reachable.${NC}"
    exit 1
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# S3 Tests
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "── S3 ────────────────────────────────────────────────────────────────────"

info "Creating bucket s3://${BUCKET}..."
if aws s3 mb "s3://${BUCKET}" --endpoint-url="${ENDPOINT}" &>/dev/null; then
  ok "Bucket created: ${BUCKET}"
else
  fail "Failed to create bucket"
fi

info "Uploading object..."
echo "Hello from Floci smoke test 🎉" > "${TMP_DIR}/hello.txt"
if aws s3 cp "${TMP_DIR}/hello.txt" "s3://${BUCKET}/hello.txt" --endpoint-url="${ENDPOINT}" &>/dev/null; then
  ok "Object uploaded: s3://${BUCKET}/hello.txt"
else
  fail "Failed to upload object"
fi

info "Downloading object..."
if aws s3 cp "s3://${BUCKET}/hello.txt" "${TMP_DIR}/hello-back.txt" --endpoint-url="${ENDPOINT}" &>/dev/null; then
  CONTENT=$(cat "${TMP_DIR}/hello-back.txt")
  if [[ "$CONTENT" == *"Hello from Floci"* ]]; then
    ok "Object downloaded and content verified."
  else
    fail "Object downloaded but content mismatch: '${CONTENT}'"
  fi
else
  fail "Failed to download object"
fi

info "Listing objects in bucket..."
COUNT=$(aws s3 ls "s3://${BUCKET}/" --endpoint-url="${ENDPOINT}" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$COUNT" -ge 1 ]]; then
  ok "Bucket listing returned ${COUNT} object(s)."
else
  fail "Bucket listing returned 0 objects."
fi

info "Cleaning up S3 bucket..."
aws s3 rb "s3://${BUCKET}" --force --endpoint-url="${ENDPOINT}" &>/dev/null && ok "Bucket deleted." || fail "Failed to delete bucket."

# ══════════════════════════════════════════════════════════════════════════════
# SQS Tests
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "── SQS ───────────────────────────────────────────────────────────────────"

info "Creating queue: ${QUEUE}..."
QUEUE_URL=$(aws sqs create-queue --queue-name "${QUEUE}" --endpoint-url="${ENDPOINT}" \
  --query 'QueueUrl' --output text 2>/dev/null)
if [[ -n "$QUEUE_URL" ]]; then
  ok "Queue created: ${QUEUE_URL}"
else
  fail "Failed to create queue"
  QUEUE_URL=""
fi

if [[ -n "$QUEUE_URL" ]]; then
  info "Sending message..."
  MSG_ID=$(aws sqs send-message --queue-url "${QUEUE_URL}" \
    --message-body "Floci SQS smoke test" \
    --endpoint-url="${ENDPOINT}" --query 'MessageId' --output text 2>/dev/null)
  if [[ -n "$MSG_ID" ]]; then
    ok "Message sent (ID: ${MSG_ID})"
  else
    fail "Failed to send message"
  fi

  info "Receiving message..."
  BODY=$(aws sqs receive-message --queue-url "${QUEUE_URL}" \
    --max-number-of-messages 1 --wait-time-seconds 3 \
    --endpoint-url="${ENDPOINT}" \
    --query 'Messages[0].Body' --output text 2>/dev/null || echo "")
  if [[ "$BODY" == *"Floci SQS smoke test"* ]]; then
    ok "Message received and body verified."
  else
    fail "Message body mismatch or empty: '${BODY}'"
  fi

  info "Deleting queue..."
  aws sqs delete-queue --queue-url "${QUEUE_URL}" --endpoint-url="${ENDPOINT}" &>/dev/null \
    && ok "Queue deleted." || fail "Failed to delete queue."
fi

# ══════════════════════════════════════════════════════════════════════════════
# Lambda Tests
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "── Lambda ────────────────────────────────────────────────────────────────"

if [[ "$SKIP_LAMBDA" == "true" ]]; then
  warn "Lambda tests skipped (--skip-lambda flag)."
elif ! command -v zip &>/dev/null; then
  warn "Lambda tests skipped ('zip' not found)."
else
  # Write a minimal handler
  cat > "${TMP_DIR}/index.js" << 'HANDLER'
exports.handler = async (event) => ({
  statusCode: 200,
  body: JSON.stringify({ message: "Hello from Floci Lambda", input: event }),
});
HANDLER

  (cd "${TMP_DIR}" && zip -q function.zip index.js)

  info "Creating Lambda function: ${LAMBDA_NAME}..."
  CREATE_OUT=$(aws lambda create-function \
    --function-name "${LAMBDA_NAME}" \
    --runtime nodejs20.x \
    --role "arn:aws:iam::000000000000:role/lambda-role" \
    --handler index.handler \
    --zip-file "fileb://${TMP_DIR}/function.zip" \
    --endpoint-url="${ENDPOINT}" \
    --query 'FunctionArn' --output text 2>/dev/null || echo "")
  if [[ -n "$CREATE_OUT" ]]; then
    ok "Lambda created: ${CREATE_OUT}"
  else
    fail "Failed to create Lambda function (docker.sock may not be mounted)"
    SKIP_LAMBDA=true
  fi

  if [[ "$SKIP_LAMBDA" != "true" ]]; then
    info "Invoking Lambda function (sync)..."
    STATUS_CODE=$(aws lambda invoke \
      --function-name "${LAMBDA_NAME}" \
      --payload '{"test":true}' \
      --cli-binary-format raw-in-base64-out \
      "${TMP_DIR}/lambda-response.json" \
      --endpoint-url="${ENDPOINT}" \
      --query 'StatusCode' --output text 2>/dev/null || echo "0")
    if [[ "$STATUS_CODE" == "200" ]]; then
      RESPONSE=$(cat "${TMP_DIR}/lambda-response.json" 2>/dev/null || echo "")
      if [[ "$RESPONSE" == *"Hello from Floci Lambda"* ]]; then
        ok "Lambda invoked successfully (statusCode: ${STATUS_CODE})."
      else
        fail "Lambda returned unexpected response: ${RESPONSE}"
      fi
    else
      fail "Lambda invocation returned HTTP ${STATUS_CODE}."
    fi

    info "Cleaning up Lambda..."
    aws lambda delete-function --function-name "${LAMBDA_NAME}" \
      --endpoint-url="${ENDPOINT}" &>/dev/null && ok "Lambda deleted." || fail "Failed to delete Lambda."
  fi
fi

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
  echo "    ${RUNTIME:-docker} logs floci"
  echo "    bash aws/scripts/stop.sh && bash aws/scripts/start.sh"
  exit 1
fi
echo ""
