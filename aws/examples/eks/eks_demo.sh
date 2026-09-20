#!/usr/bin/env bash
# =============================================================================
# examples/eks/eks_demo.sh
#
# Demonstrates AWS EKS cluster management and Spark Job submission
# concepts against Floci:
#   - Create EKS Cluster
#   - List EKS Clusters
#   - Describe EKS Cluster
#   - Generate K8s Spark Job Manifest
#   - Explain Spark on EKS (EMR on EKS / Direct spark-submit) execution
#   - Delete EKS Cluster (cleanup)
#
# Prerequisites:
#   export AWS_ENDPOINT_URL=http://localhost:4566
#   export AWS_ACCESS_KEY_ID=test
#   export AWS_SECRET_ACCESS_KEY=test
#   export AWS_DEFAULT_REGION=us-east-1
# =============================================================================

set -euo pipefail

ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:4566}"
CLUSTER_NAME="floci-spark-cluster"
ROLE_ARN="arn:aws:iam::000000000000:role/eks-spark-role"
MANIFEST_FILE="/tmp/spark-pi-job.yaml"

echo "=== Floci EKS & Spark on EKS Demo ==="
echo "Endpoint     : $ENDPOINT"
echo "Cluster Name : $CLUSTER_NAME"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 1. Create EKS Cluster
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Creating EKS Cluster ---"
aws eks create-cluster \
  --name "$CLUSTER_NAME" \
  --role-arn "$ROLE_ARN" \
  --resources-vpc-config '{}' \
  --endpoint-url="$ENDPOINT"
echo "Cluster creation initiated."
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 2. List EKS Clusters
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Listing EKS Clusters ---"
aws eks list-clusters --endpoint-url="$ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 3. Describe EKS Cluster
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Describing EKS Cluster ---"
aws eks describe-cluster \
  --name "$CLUSTER_NAME" \
  --endpoint-url="$ENDPOINT"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 4. Generate Kubernetes Manifest for a Spark Job
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Generating Spark Job Kubernetes Manifest ---"
cat << 'EOF' > "$MANIFEST_FILE"
apiVersion: v1
kind: Pod
metadata:
  name: spark-pi-driver
  namespace: default
  labels:
    spark-role: driver
spec:
  containers:
    - name: spark-pi
      image: apache/spark:3.5.0
      command:
        - "/opt/spark/bin/spark-submit"
        - "--class"
        - "org.apache.spark.examples.SparkPi"
        - "--master"
        - "local[2]"
        - "/opt/spark/examples/jars/spark-examples_2.12-3.5.0.jar"
        - "100"
      resources:
        limits:
          cpu: "2"
          memory: "2Gi"
        requests:
          cpu: "1"
          memory: "1Gi"
  restartPolicy: Never
EOF

echo "Manifest generated at $MANIFEST_FILE"
echo "--------------------------------------------------------"
cat "$MANIFEST_FILE"
echo "--------------------------------------------------------"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 5. Explaining Spark Job Submission on EKS
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Explaining Spark Job Submission on EKS ---"
echo "To submit this Spark job to a running EKS cluster, you would usually:"
echo "1. Connect your local kubectl to EKS:"
echo "   aws eks update-kubeconfig --name $CLUSTER_NAME --endpoint-url=$ENDPOINT"
echo ""
echo "2. Apply the Spark Job manifest to Kubernetes:"
echo "   kubectl apply -f $MANIFEST_FILE"
echo ""
echo "3. Monitor the driver pod logs to see Spark computing Pi:"
echo "   kubectl logs -f spark-pi-driver"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 6. Cleanup — Delete Cluster
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Cleaning up EKS Cluster ---"
aws eks delete-cluster \
  --name "$CLUSTER_NAME" \
  --endpoint-url="$ENDPOINT"
echo "Cluster deletion requested."
echo ""

# Clean up local file
rm -f "$MANIFEST_FILE"

echo "=== EKS & Spark on EKS demo complete ==="
