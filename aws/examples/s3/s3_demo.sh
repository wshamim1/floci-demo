#!/usr/bin/env bash
# =============================================================================
# examples/s3/s3_demo.sh
#
# Demonstrates core S3 operations against Floci:
#   - Create bucket
#   - Upload / download objects
#   - List objects
#   - Delete bucket
#
# Prerequisites:
#   export AWS_ENDPOINT_URL=http://localhost:4566
#   export AWS_ACCESS_KEY_ID=floci
#   export AWS_SECRET_ACCESS_KEY=floci
#   export AWS_DEFAULT_REGION=us-east-1
# =============================================================================

set -euo pipefail

ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:4566}"
BUCKET="my-floci-bucket"
OBJECT_KEY="hello.txt"
LOCAL_FILE="/tmp/floci_hello.txt"
DOWNLOAD_FILE="/tmp/floci_downloaded.txt"

echo "=== Floci S3 Demo ==="
echo "Endpoint : $ENDPOINT"
echo "Bucket   : $BUCKET"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 1. Create bucket
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Creating bucket ---"
aws s3 mb "s3://$BUCKET" --endpoint-url="$ENDPOINT"
# Expected: make_bucket: my-floci-bucket
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 2. List buckets
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Listing all buckets ---"
aws s3 ls --endpoint-url="$ENDPOINT"
# Expected: <date>  my-floci-bucket
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 3. Upload an object
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Uploading object ---"
echo "Hello from Floci!" > "$LOCAL_FILE"
aws s3 cp "$LOCAL_FILE" "s3://$BUCKET/$OBJECT_KEY" --endpoint-url="$ENDPOINT"
# Expected: upload: /tmp/floci_hello.txt to s3://my-floci-bucket/hello.txt
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 4. List objects in the bucket
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Listing objects in bucket ---"
aws s3 ls "s3://$BUCKET/" --endpoint-url="$ENDPOINT"
# Expected: <date>  20  hello.txt
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 5. Download the object
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Downloading object ---"
aws s3 cp "s3://$BUCKET/$OBJECT_KEY" "$DOWNLOAD_FILE" --endpoint-url="$ENDPOINT"
echo "File contents:"
cat "$DOWNLOAD_FILE"
# Expected: Hello from Floci!
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 6. Cleanup — delete the bucket and its contents
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Deleting bucket (--force removes all objects first) ---"
aws s3 rb "s3://$BUCKET" --force --endpoint-url="$ENDPOINT"
# Expected: remove_bucket: my-floci-bucket
echo ""

# Remove temp files
rm -f "$LOCAL_FILE" "$DOWNLOAD_FILE"

echo "=== S3 demo complete ==="
