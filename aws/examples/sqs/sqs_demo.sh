#!/usr/bin/env bash
# =============================================================================
# examples/sqs/sqs_demo.sh
#
# Demonstrates core SQS operations against Floci:
#   - Create queue
#   - List queues
#   - Send single and batch messages
#   - Receive messages (long-poll)
#   - Delete queue
#
# Prerequisites:
#   export AWS_ENDPOINT_URL=http://localhost:4566
#   export AWS_ACCESS_KEY_ID=floci
#   export AWS_SECRET_ACCESS_KEY=floci
#   export AWS_DEFAULT_REGION=us-east-1
# =============================================================================

set -euo pipefail

ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:4566}"
QUEUE_NAME="my-floci-queue"

echo "=== Floci SQS Demo ==="
echo "Endpoint : $ENDPOINT"
echo "Queue    : $QUEUE_NAME"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 1. Create a standard queue
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Creating queue ---"
aws sqs create-queue \
  --queue-name "$QUEUE_NAME" \
  --endpoint-url="$ENDPOINT"
# Expected:
# {
#     "QueueUrl": "http://localhost:4566/000000000000/my-floci-queue"
# }
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 2. List queues
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Listing queues ---"
aws sqs list-queues --endpoint-url="$ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 3. Resolve the queue URL for subsequent commands
# ──────────────────────────────────────────────────────────────────────────────
QUEUE_URL=$(aws sqs get-queue-url \
  --queue-name "$QUEUE_NAME" \
  --endpoint-url="$ENDPOINT" \
  --query 'QueueUrl' \
  --output text)
echo "Queue URL: $QUEUE_URL"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 4. Send a single message
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Sending a single message ---"
aws sqs send-message \
  --queue-url "$QUEUE_URL" \
  --message-body "Hello from Floci SQS" \
  --endpoint-url="$ENDPOINT"
# Expected:
# {
#     "MD5OfMessageBody": "...",
#     "MessageId": "550e8400-..."
# }
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 5. Send a batch of messages
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Sending a batch of two messages ---"
aws sqs send-message-batch \
  --queue-url "$QUEUE_URL" \
  --entries \
    '{"Id":"msg1","MessageBody":"First message"}' \
    '{"Id":"msg2","MessageBody":"Second message"}' \
  --endpoint-url="$ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 6. Receive messages (long-poll, up to 10 at once)
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Receiving messages ---"
aws sqs receive-message \
  --queue-url "$QUEUE_URL" \
  --max-number-of-messages 10 \
  --wait-time-seconds 5 \
  --endpoint-url="$ENDPOINT"
# Expected: JSON array containing all three messages sent above
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 7. Cleanup — delete the queue
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Deleting queue ---"
aws sqs delete-queue \
  --queue-url "$QUEUE_URL" \
  --endpoint-url="$ENDPOINT"
echo "Queue deleted."
echo ""

echo "=== SQS demo complete ==="
