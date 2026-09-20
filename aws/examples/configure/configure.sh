#!/usr/bin/env bash
# =============================================================================
# examples/configure/configure.sh
#
# Three ways to configure the AWS CLI to talk to Floci.
# Run any one section that fits your workflow — you do not need all three.
# =============================================================================

set -euo pipefail

echo "=== Floci AWS CLI Configuration ==="
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# Option 1: Environment variables (recommended — works for every CLI command)
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Option 1: Environment variables ---"

export AWS_ACCESS_KEY_ID=any-value-works
export AWS_SECRET_ACCESS_KEY=any-value-works
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:4566

echo "AWS_ACCESS_KEY_ID    = $AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY= $AWS_SECRET_ACCESS_KEY"
echo "AWS_DEFAULT_REGION   = $AWS_DEFAULT_REGION"
echo "AWS_ENDPOINT_URL     = $AWS_ENDPOINT_URL"
echo ""

# Verify it works — list S3 buckets
echo "Listing S3 buckets (should return empty or existing buckets):"
aws s3 ls
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# Option 2: Per-command --endpoint-url flag (useful for one-off tests)
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Option 2: Per-command flag ---"
echo "Running: aws s3 ls --endpoint-url=http://localhost:4566"
aws s3 ls --endpoint-url=http://localhost:4566
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# Option 3: Named AWS profile in ~/.aws/config
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Option 3: Named profile ---"

# Append [profile floci] only if it isn't already present
if ! grep -q '\[profile floci\]' ~/.aws/config 2>/dev/null; then
  mkdir -p ~/.aws
  cat >> ~/.aws/config << 'EOF'

[profile floci]
region = us-east-1
output = json
endpoint_url = http://localhost:4566
EOF
  echo "Profile 'floci' written to ~/.aws/config"
else
  echo "Profile 'floci' already exists in ~/.aws/config — skipping"
fi

echo "Running: aws s3 ls --profile floci"
AWS_ACCESS_KEY_ID=floci AWS_SECRET_ACCESS_KEY=floci aws s3 ls --profile floci
echo ""

echo "=== Configuration complete ==="
