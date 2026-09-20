#!/usr/bin/env bash
# env.sh — Print GCP emulator env-var exports. Eval this in your shell:
#   eval $(bash gcp/scripts/env.sh)
# Or source it:
#   source <(bash gcp/scripts/env.sh)
#
# These variables redirect the Google Cloud client libraries and gcloud CLI
# to the local emulators instead of real GCP.

echo 'export STORAGE_EMULATOR_HOST=http://localhost:4443'
echo 'export STORAGE_API_ENDPOINT_OVERRIDE=http://localhost:4443/storage/v1/'
echo 'export PUBSUB_EMULATOR_HOST=localhost:8085'
echo 'export PUBSUB_PROJECT_ID=floci-project'
echo 'export GCLOUD_PROJECT=floci-project'
echo 'export GOOGLE_CLOUD_PROJECT=floci-project'
# Disable ADC (Application Default Credentials) check — emulators don't need real credentials
echo 'export GOOGLE_APPLICATION_CREDENTIALS=""'
