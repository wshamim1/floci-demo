#!/usr/bin/env bash
# env.sh — Print Floci AWS env-var exports. Eval this in your shell:
#   eval $(bash aws/scripts/env.sh)
# Or source it:
#   source <(bash aws/scripts/env.sh)
#
# AWS_PROFILE=floci ensures the 'floci' profile's credentials (key=test) are
# used instead of any real AWS profile in ~/.aws/credentials.
# AWS CLI v1 does not honour endpoint_url in ~/.aws/config, so
# AWS_ENDPOINT_URL is the only reliable way to redirect the endpoint.

echo 'export AWS_ENDPOINT_URL=http://localhost:4566'
echo 'export AWS_ACCESS_KEY_ID=test'
echo 'export AWS_SECRET_ACCESS_KEY=test'
echo 'export AWS_DEFAULT_REGION=us-east-1'
echo 'export AWS_PROFILE=floci'
