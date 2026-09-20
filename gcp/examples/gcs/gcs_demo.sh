#!/usr/bin/env bash
# =============================================================================
# examples/gcs/gcs_demo.sh
#
# Demonstrates core GCS operations against the fake-gcs-server emulator
# using the JSON REST API (no gcloud credentials needed):
#   - Create bucket
#   - Upload / download objects
#   - List objects
#   - Delete object and bucket
#
# Prerequisites:
#   eval $(bash gcp/scripts/env.sh)
#   # or manually:
#   export STORAGE_EMULATOR_HOST=http://localhost:4443
# =============================================================================

set -euo pipefail

GCS_ENDPOINT="${STORAGE_EMULATOR_HOST:-http://localhost:4443}"
PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-floci-project}"
BUCKET="my-floci-gcs-bucket"
LOCAL_FILE="/tmp/floci_gcs_hello.txt"
DOWNLOAD_FILE="/tmp/floci_gcs_downloaded.txt"

echo "=== Floci GCS Demo ==="
echo "Endpoint : $GCS_ENDPOINT"
echo "Bucket   : $BUCKET"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 1. Create bucket
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Creating bucket ---"
curl -s -X POST \
  "${GCS_ENDPOINT}/storage/v1/b?project=${PROJECT_ID}" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"${BUCKET}\"}" | python3 -m json.tool
# Expected: JSON with "name": "my-floci-gcs-bucket"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 2. Upload an object
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Uploading object ---"
echo "Hello from Floci GCP!" > "$LOCAL_FILE"
curl -s -X POST \
  "${GCS_ENDPOINT}/upload/storage/v1/b/${BUCKET}/o?uploadType=media&name=hello.txt" \
  -H "Content-Type: text/plain" \
  --data-binary @"$LOCAL_FILE" | python3 -m json.tool
# Expected: JSON with "name": "hello.txt"
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 3. List objects in the bucket
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Listing objects ---"
curl -s "${GCS_ENDPOINT}/storage/v1/b/${BUCKET}/o" | python3 -m json.tool
# Expected: JSON with items[] containing hello.txt
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 4. Download the object
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Downloading object ---"
curl -s "${GCS_ENDPOINT}/storage/v1/b/${BUCKET}/o/hello.txt?alt=media" \
  -o "$DOWNLOAD_FILE"
echo "File contents:"
cat "$DOWNLOAD_FILE"
# Expected: Hello from Floci GCP!
echo ""

# ──────────────────────────────────────────────────────────────────────────────
# 5. Cleanup
# ──────────────────────────────────────────────────────────────────────────────
echo "--- Cleaning up ---"
curl -s -X DELETE "${GCS_ENDPOINT}/storage/v1/b/${BUCKET}/o/hello.txt" \
  -o /dev/null -w "Delete object HTTP %{http_code}\n"

curl -s -X DELETE "${GCS_ENDPOINT}/storage/v1/b/${BUCKET}" \
  -o /dev/null -w "Delete bucket HTTP %{http_code}\n"

rm -f "$LOCAL_FILE" "$DOWNLOAD_FILE"
echo ""
echo "=== GCS demo complete ==="
