#!/usr/bin/env bash
# =============================================================================
# examples/ecs/ecs_demo.sh
#
# Demonstrates core ECS (Elastic Container Service) operations against Floci:
#   - Create ECS Cluster
#   - List ECS Clusters
#   - Register Task Definition (running a lightweight web server)
#   - List Task Definitions
#   - Deregister Task Definition & Delete Cluster (cleanup)
#
# Prerequisites:
#   export AWS_ENDPOINT_URL=http://localhost:4566
#   export AWS_ACCESS_KEY_ID=test
#   export AWS_SECRET_ACCESS_KEY=test
#   export AWS_DEFAULT_REGION=us-east-1
# =============================================================================

set -euo pipefail

ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:4566}"
CLUSTER_NAME="my-floci-ecs"
TASK_FAMILY="web-app-task"

echo "=== Floci ECS Demo ==="
echo "Endpoint     : $ENDPOINT"
echo "Cluster Name : $CLUSTER_NAME"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 1. Create ECS Cluster
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Creating ECS Cluster ---"
aws ecs create-cluster \
  --cluster-name "$CLUSTER_NAME" \
  --endpoint-url="$ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 2. List ECS Clusters
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Listing ECS Clusters ---"
aws ecs list-clusters --endpoint-url="$ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 3. Register ECS Task Definition
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Registering ECS Task Definition ---"
aws ecs register-task-definition \
  --family "$TASK_FAMILY" \
  --container-definitions '[
    {
      "name": "web-container",
      "image": "nginx:alpine",
      "cpu": 128,
      "memory": 256,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 8080
        }
      ]
    }
  ]' \
  --endpoint-url="$ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 4. List Task Definitions
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Listing Task Definitions ---"
aws ecs list-task-definitions --endpoint-url="$ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 5. Cleanup — Deregister Task & Delete Cluster
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Cleaning up ECS Resources ---"
# Get the active task definition revision (typically family:1)
TASK_ARN=$(aws ecs list-task-definitions --family "$TASK_FAMILY" --endpoint-url="$ENDPOINT" --query 'taskDefinitionArns[0]' --output text)

if [[ "$TASK_ARN" != "None" && -n "$TASK_ARN" ]]; then
  echo "Deregistering Task Definition: $TASK_ARN"
  aws ecs deregister-task-definition \
    --task-definition "$TASK_ARN" \
    --endpoint-url="$ENDPOINT" > /dev/null
fi

echo "Deleting ECS Cluster: $CLUSTER_NAME"
aws ecs delete-cluster \
  --cluster "$CLUSTER_NAME" \
  --endpoint-url="$ENDPOINT" > /dev/null

echo "ECS Cleanup complete."
echo ""

echo "=== ECS demo complete ==="
