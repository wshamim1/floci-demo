#!/usr/bin/env bash
# =============================================================================
# examples/pubsub/pubsub_demo.sh
#
# Demonstrates core Pub/Sub operations against the GCP Pub/Sub emulator
# using the HTTP REST API:
#   - Create topic
#   - Create subscription
#   - Publish messages
#   - Pull and acknowledge messages
#   - Delete subscription and topic
#
# Prerequisites:
#   eval $(bash gcp/scripts/env.sh)
#   # Pub/Sub emulator must be running (bash gcp/scripts/start.sh)
# =============================================================================

set -euo pipefail

PUBSUB_HTTP="http://localhost:8085"
PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-floci-project}"
TOPIC="my-floci-topic"
SUBSCRIPTION="my-floci-subscription"

echo "=== Floci GCP Pub/Sub Demo ==="
echo "Endpoint     : $PUBSUB_HTTP"
echo "Project      : $PROJECT_ID"
echo "Topic        : $TOPIC"
echo "Subscription : $SUBSCRIPTION"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 1. Create topic
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Creating topic ---"
curl -s -X PUT \
  "${PUBSUB_HTTP}/v1/projects/${PROJECT_ID}/topics/${TOPIC}" \
  -H "Content-Type: application/json" \
  -d "{}" | python3 -m json.tool
# Expected: { "name": "projects/floci-project/topics/my-floci-topic" }
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 2. Create subscription
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Creating subscription ---"
curl -s -X PUT \
  "${PUBSUB_HTTP}/v1/projects/${PROJECT_ID}/subscriptions/${SUBSCRIPTION}" \
  -H "Content-Type: application/json" \
  -d "{\"topic\":\"projects/${PROJECT_ID}/topics/${TOPIC}\"}" | python3 -m json.tool
# Expected: JSON with "name" and "topic" fields
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 3. Publish messages
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Publishing messages ---"
MSG1=$(echo -n "Hello from Floci Pub/Sub! (1)" | base64)
MSG2=$(echo -n "Hello from Floci Pub/Sub! (2)" | base64)
curl -s -X POST \
  "${PUBSUB_HTTP}/v1/projects/${PROJECT_ID}/topics/${TOPIC}:publish" \
  -H "Content-Type: application/json" \
  -d "{\"messages\":[{\"data\":\"${MSG1}\"},{\"data\":\"${MSG2}\"}]}" | python3 -m json.tool
# Expected: { "messageIds": ["1", "2"] }
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 4. Pull messages
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Pulling messages ---"
PULL_RESP=$(curl -s -X POST \
  "${PUBSUB_HTTP}/v1/projects/${PROJECT_ID}/subscriptions/${SUBSCRIPTION}:pull" \
  -H "Content-Type: application/json" \
  -d '{"maxMessages":2}')
echo "$PULL_RESP" | python3 -m json.tool

# Decode and print message content
echo "Decoded messages:"
echo "$PULL_RESP" | python3 -c "
import sys, json, base64
msgs = json.load(sys.stdin).get('receivedMessages', [])
for m in msgs:
    print(' -', base64.b64decode(m['message']['data']).decode())
"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 5. Acknowledge messages
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Acknowledging messages ---"
ACK_IDS=$(echo "$PULL_RESP" | python3 -c "
import sys, json
msgs = json.load(sys.stdin).get('receivedMessages', [])
print(json.dumps([m['ackId'] for m in msgs]))
")
curl -s -X POST \
  "${PUBSUB_HTTP}/v1/projects/${PROJECT_ID}/subscriptions/${SUBSCRIPTION}:acknowledge" \
  -H "Content-Type: application/json" \
  -d "{\"ackIds\":${ACK_IDS}}"
echo "Messages acknowledged."
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 6. Cleanup
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Cleaning up ---"
curl -s -X DELETE \
  "${PUBSUB_HTTP}/v1/projects/${PROJECT_ID}/subscriptions/${SUBSCRIPTION}" \
  -o /dev/null -w "Delete subscription HTTP %{http_code}\n"

curl -s -X DELETE \
  "${PUBSUB_HTTP}/v1/projects/${PROJECT_ID}/topics/${TOPIC}" \
  -o /dev/null -w "Delete topic HTTP %{http_code}\n"

echo ""
echo "=== Pub/Sub demo complete ==="
