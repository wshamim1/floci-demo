#!/usr/bin/env bash
# test.sh — Smoke-test GCP emulators: GCS and Pub/Sub
# Requires: gsutil or gcloud (Google Cloud SDK), curl
# Usage:
#   bash gcp/scripts/test.sh
#   bash gcp/scripts/test.sh --skip-pubsub   # skip Pub/Sub (gRPC-only)

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS=0; FAIL=0

info()    { echo -e "${CYAN}[TEST]${NC}  $*"; }
ok()      { echo -e "${GREEN}[PASS]${NC}  $*"; PASS=$((PASS + 1)); }
fail()    { echo -e "${RED}[FAIL]${NC}  $*"; FAIL=$((FAIL + 1)); }
warn()    { echo -e "${YELLOW}[SKIP]${NC}  $*"; }

SKIP_PUBSUB=false
for arg in "$@"; do
  [[ "$arg" == "--skip-pubsub" ]] && SKIP_PUBSUB=true
done

export STORAGE_EMULATOR_HOST=http://localhost:4443
export PUBSUB_EMULATOR_HOST=localhost:8085
export PUBSUB_PROJECT_ID=floci-project
export GCLOUD_PROJECT=floci-project
export GOOGLE_CLOUD_PROJECT=floci-project
export GOOGLE_APPLICATION_CREDENTIALS=""

GCS_ENDPOINT="http://localhost:4443"
PROJECT_ID="floci-project"
BUCKET="floci-smoke-$$"
TOPIC="floci-smoke-topic-$$"
SUBSCRIPTION="floci-smoke-sub-$$"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║    Floci GCP Smoke Tests              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# ── GCS connectivity ───────────────────────────────────────────────────────────
info "Checking GCS emulator endpoint..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  "${GCS_ENDPOINT}/storage/v1/b" 2>/dev/null || echo "000")
if [[ "$STATUS" == "200" ]]; then
  ok "GCS emulator reachable (HTTP ${STATUS})"
else
  fail "Cannot reach GCS at ${GCS_ENDPOINT}. Is it running? (bash gcp/scripts/start.sh)"
  echo ""
  echo -e "${RED}Aborting — GCS emulator is not reachable.${NC}"
  exit 1
fi

# ══════════════════════════════════════════════════════════════════════════════
# GCS Tests (via REST API — no gcloud credential setup needed)
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "── GCS (Cloud Storage) ───────────────────────────────────────────────────"

info "Creating bucket: ${BUCKET}..."
CREATE_RESP=$(curl -s -X POST \
  "${GCS_ENDPOINT}/storage/v1/b?project=${PROJECT_ID}" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"${BUCKET}\"}" 2>/dev/null)
if echo "$CREATE_RESP" | grep -q "\"name\""; then
  ok "Bucket created: ${BUCKET}"
else
  fail "Failed to create bucket. Response: ${CREATE_RESP}"
fi

info "Uploading object..."
echo "Hello from Floci GCP smoke test!" > "${TMP_DIR}/hello.txt"
UPLOAD_RESP=$(curl -s -X POST \
  "${GCS_ENDPOINT}/upload/storage/v1/b/${BUCKET}/o?uploadType=media&name=hello.txt" \
  -H "Content-Type: text/plain" \
  --data-binary @"${TMP_DIR}/hello.txt" 2>/dev/null)
if echo "$UPLOAD_RESP" | grep -q "\"name\""; then
  ok "Object uploaded: gs://${BUCKET}/hello.txt"
else
  fail "Failed to upload object. Response: ${UPLOAD_RESP}"
fi

info "Downloading object..."
DOWNLOAD_CONTENT=$(curl -s \
  "${GCS_ENDPOINT}/storage/v1/b/${BUCKET}/o/hello.txt?alt=media" 2>/dev/null)
if [[ "$DOWNLOAD_CONTENT" == *"Hello from Floci GCP"* ]]; then
  ok "Object downloaded and content verified."
else
  fail "Object content mismatch: '${DOWNLOAD_CONTENT}'"
fi

info "Listing objects in bucket..."
LIST_RESP=$(curl -s \
  "${GCS_ENDPOINT}/storage/v1/b/${BUCKET}/o" 2>/dev/null)
if echo "$LIST_RESP" | grep -q "hello.txt"; then
  ok "Bucket listing verified (found hello.txt)."
else
  fail "Bucket listing empty or missing object."
fi

info "Deleting object..."
DEL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "${GCS_ENDPOINT}/storage/v1/b/${BUCKET}/o/hello.txt" 2>/dev/null || echo "000")
if [[ "$DEL_STATUS" == "204" || "$DEL_STATUS" == "200" ]]; then
  ok "Object deleted."
else
  fail "Failed to delete object (HTTP ${DEL_STATUS})."
fi

info "Deleting bucket..."
DEL_BKT=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "${GCS_ENDPOINT}/storage/v1/b/${BUCKET}" 2>/dev/null || echo "000")
if [[ "$DEL_BKT" == "204" || "$DEL_BKT" == "200" ]]; then
  ok "Bucket deleted."
else
  fail "Failed to delete bucket (HTTP ${DEL_BKT})."
fi

# ══════════════════════════════════════════════════════════════════════════════
# Pub/Sub Tests (via REST API against emulator)
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "── Pub/Sub ───────────────────────────────────────────────────────────────"

if [[ "$SKIP_PUBSUB" == "true" ]]; then
  warn "Pub/Sub tests skipped (--skip-pubsub flag)."
else
  # The Pub/Sub emulator exposes an HTTP REST endpoint on the same port
  PUBSUB_HTTP="http://localhost:8085"
  PUBSUB_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    "${PUBSUB_HTTP}/v1/projects/${PROJECT_ID}/topics" 2>/dev/null || echo "000")

  if [[ ! "$PUBSUB_STATUS" =~ ^[2-4] ]]; then
    warn "Pub/Sub emulator not reachable at ${PUBSUB_HTTP} — skipping Pub/Sub tests."
    SKIP_PUBSUB=true
  fi
fi

if [[ "$SKIP_PUBSUB" == "false" ]]; then
  PUBSUB_HTTP="http://localhost:8085"

  info "Creating topic: ${TOPIC}..."
  TOPIC_RESP=$(curl -s -X PUT \
    "${PUBSUB_HTTP}/v1/projects/${PROJECT_ID}/topics/${TOPIC}" \
    -H "Content-Type: application/json" -d "{}" 2>/dev/null)
  if echo "$TOPIC_RESP" | grep -q "\"name\""; then
    ok "Topic created: ${TOPIC}"
  else
    fail "Failed to create topic. Response: ${TOPIC_RESP}"
    SKIP_PUBSUB=true
  fi
fi

if [[ "$SKIP_PUBSUB" == "false" ]]; then
  PUBSUB_HTTP="http://localhost:8085"

  info "Creating subscription: ${SUBSCRIPTION}..."
  SUB_RESP=$(curl -s -X PUT \
    "${PUBSUB_HTTP}/v1/projects/${PROJECT_ID}/subscriptions/${SUBSCRIPTION}" \
    -H "Content-Type: application/json" \
    -d "{\"topic\":\"projects/${PROJECT_ID}/topics/${TOPIC}\"}" 2>/dev/null)
  if echo "$SUB_RESP" | grep -q "\"name\""; then
    ok "Subscription created: ${SUBSCRIPTION}"
  else
    fail "Failed to create subscription. Response: ${SUB_RESP}"
  fi

  info "Publishing message..."
  MSG_B64=$(echo -n "Hello from Floci Pub/Sub!" | base64)
  PUB_RESP=$(curl -s -X POST \
    "${PUBSUB_HTTP}/v1/projects/${PROJECT_ID}/topics/${TOPIC}:publish" \
    -H "Content-Type: application/json" \
    -d "{\"messages\":[{\"data\":\"${MSG_B64}\"}]}" 2>/dev/null)
  if echo "$PUB_RESP" | grep -q "messageIds"; then
    ok "Message published."
  else
    fail "Failed to publish message. Response: ${PUB_RESP}"
  fi

  info "Pulling message..."
  PULL_RESP=$(curl -s -X POST \
    "${PUBSUB_HTTP}/v1/projects/${PROJECT_ID}/subscriptions/${SUBSCRIPTION}:pull" \
    -H "Content-Type: application/json" \
    -d '{"maxMessages":1}' 2>/dev/null)
  DECODED=$(echo "$PULL_RESP" | grep -o '"data":"[^"]*"' | head -1 | \
    sed 's/"data":"//;s/"//' | base64 --decode 2>/dev/null || echo "")
  if [[ "$DECODED" == *"Hello from Floci Pub/Sub"* ]]; then
    ok "Message pulled and content verified."
  else
    fail "Message content mismatch or empty: '${DECODED}'"
  fi

  info "Deleting subscription..."
  curl -s -X DELETE \
    "${PUBSUB_HTTP}/v1/projects/${PROJECT_ID}/subscriptions/${SUBSCRIPTION}" &>/dev/null \
    && ok "Subscription deleted." || fail "Failed to delete subscription."

  info "Deleting topic..."
  curl -s -X DELETE \
    "${PUBSUB_HTTP}/v1/projects/${PROJECT_ID}/topics/${TOPIC}" &>/dev/null \
    && ok "Topic deleted." || fail "Failed to delete topic."
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
  echo "    docker logs floci-gcs"
  echo "    docker logs floci-pubsub"
  echo "    bash gcp/scripts/stop.sh && bash gcp/scripts/start.sh"
  exit 1
fi
echo ""
