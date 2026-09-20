#!/usr/bin/env bash
# env.sh — Print Azurite connection string and env-var exports. Eval this in your shell:
#   eval $(bash azure/scripts/env.sh)
# Or source it:
#   source <(bash azure/scripts/env.sh)
#
# Azurite ships with a fixed well-known account name and key.
# These credentials are documented at:
#   https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite#well-known-storage-account-and-key

ACCOUNT_NAME="devstoreaccount1"
ACCOUNT_KEY="Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=="

echo "export AZURE_STORAGE_ACCOUNT=${ACCOUNT_NAME}"
echo "export AZURE_STORAGE_KEY=${ACCOUNT_KEY}"
echo "export AZURE_STORAGE_CONNECTION_STRING=\"DefaultEndpointsProtocol=http;AccountName=${ACCOUNT_NAME};AccountKey=${ACCOUNT_KEY};BlobEndpoint=http://127.0.0.1:10000/${ACCOUNT_NAME};QueueEndpoint=http://127.0.0.1:10001/${ACCOUNT_NAME};TableEndpoint=http://127.0.0.1:10002/${ACCOUNT_NAME}\""
echo "export AZURE_BLOB_ENDPOINT=http://127.0.0.1:10000/${ACCOUNT_NAME}"
echo "export AZURE_QUEUE_ENDPOINT=http://127.0.0.1:10001/${ACCOUNT_NAME}"
echo "export AZURE_TABLE_ENDPOINT=http://127.0.0.1:10002/${ACCOUNT_NAME}"
