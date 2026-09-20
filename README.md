# Floci — Local AWS Emulator

Floci runs a local AWS-compatible endpoint on **http://localhost:4566**, letting you develop and test S3, SQS, Lambda, DynamoDB, and more without touching a real AWS account.

---

## Requirements

| Tool | Minimum version | Notes |
|------|----------------|-------|
| macOS | 12 Monterey+ | arm64 or x86_64 |
| Docker Desktop **or** Podman | Latest stable | One runtime is enough |
| AWS CLI | v2 | `brew install awscli` |

---

## Quick Start

### 1. Install dependencies

```bash
bash aws/scripts/install.sh
```

The script auto-detects Docker or Podman. Force a specific runtime with `--docker` or `--podman`.

### 2. Start Floci

```bash
bash aws/scripts/start.sh
```

Floci will be available at **http://localhost:4566** within ~1 second.

### 3. Set environment variables

Every terminal that uses the AWS CLI must point at the local endpoint. Run once per session:

```bash
eval $(bash aws/scripts/env.sh)
```

Or export them manually:

```bash
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_PROFILE=floci
```

> **Tip — make it permanent:** Add all five `export` lines above to `~/.zshrc` (or `~/.bashrc`) so they are set automatically in every new terminal. This is strongly recommended — without `AWS_PROFILE=floci`, the AWS CLI will use the real credentials in `~/.aws/credentials` and return `InvalidClientTokenId` errors even when `AWS_ENDPOINT_URL` is set.

### 4. Verify

```bash
aws s3 ls
```

You should see a list of any existing buckets (empty on a fresh install).

---

## Examples

The [`aws/examples/`](aws/examples/) folder contains self-contained, runnable examples for every supported service:

| Directory | Service | What it covers |
|-----------|---------|----------------|
| [`aws/examples/configure/`](aws/examples/configure/) | AWS CLI | All three credential/endpoint patterns |
| [`aws/examples/s3/`](aws/examples/s3/) | S3 | Buckets, upload/download, list, delete |
| [`aws/examples/sqs/`](aws/examples/sqs/) | SQS | Queues, single/batch send, receive, delete |
| [`aws/examples/lambda/`](aws/examples/lambda/) | Lambda | Deploy a Node.js function, sync/async invoke |
| [`aws/examples/terraform/`](aws/examples/terraform/) | Terraform | Full `terraform apply` against Floci (S3 + SQS) |

See [`aws/examples/README.md`](aws/examples/README.md) for prerequisites and usage.

---

## Web UI

Open **http://localhost:4566/_floci/ui** in your browser for the Cloud Explorer — a visual dashboard of all local AWS resources.

---

## AWS CLI Usage

> ⚠️ **Before running any AWS CLI command**, make sure the environment variables are set in your current terminal:
> ```bash
> eval $(bash aws/scripts/env.sh)
> ```
> If you skip this step the CLI will target real AWS and return `InvalidClientTokenId` or `NoSuchBucket` errors.

> **Important:** always use the `s3://` URI scheme when referring to a bucket or object — `aws s3 ls s3://my-bucket`, not `aws s3 ls my-bucket`.

### S3

```bash
# List all buckets
aws s3 ls

# Create a bucket
aws s3 mb s3://my-bucket

# Upload a file
aws s3 cp ./file.txt s3://my-bucket/file.txt

# List objects inside a bucket  ← note s3://bucket-name, NOT just bucket-name
aws s3 ls s3://my-bucket

# Download a file
aws s3 cp s3://my-bucket/file.txt ./file.txt

# Delete a bucket and all its contents
aws s3 rb s3://my-bucket --force
```

### SQS

```bash
# Create a queue
aws sqs create-queue --queue-name my-queue

# Send a message (single line — avoids shell continuation issues)
aws sqs send-message --queue-url http://localhost:4566/000000000000/my-queue --message-body "hello"

# Receive a message
aws sqs receive-message --queue-url http://localhost:4566/000000000000/my-queue --max-number-of-messages 1
```

### DynamoDB

```bash
# Create a table
aws dynamodb create-table \
  --table-name users \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

# Put an item
aws dynamodb put-item \
  --table-name users \
  --item '{"id":{"S":"1"},"name":{"S":"Alice"}}'

# Get an item
aws dynamodb get-item \
  --table-name users \
  --key '{"id":{"S":"1"}}'
```

### Lambda

```bash
# Create a function (Node.js 20)
aws lambda create-function \
  --function-name my-fn \
  --runtime nodejs20.x \
  --role arn:aws:iam::000000000000:role/lambda-role \
  --handler index.handler \
  --zip-file fileb://function.zip

# Invoke synchronously
aws lambda invoke \
  --function-name my-fn \
  --payload '{"key":"value"}' \
  --cli-binary-format raw-in-base64-out \
  response.json && cat response.json
```

---

## Scripts Reference

| Script | Description |
|--------|-------------|
| `bash aws/scripts/install.sh` | Install Homebrew, container runtime, AWS CLI, Floci CLI, and pull the image |
| `bash aws/scripts/install.sh --docker` | Force Docker Desktop |
| `bash aws/scripts/install.sh --podman` | Force Podman |
| `bash aws/scripts/start.sh` | Start the Floci container |
| `bash aws/scripts/start.sh --persist ./data` | Start with a custom host directory for persistence |
| `bash aws/scripts/stop.sh` | Stop the container (data is preserved) |
| `bash aws/scripts/teardown.sh` | Stop and remove the container (data preserved) |
| `bash aws/scripts/teardown.sh --purge` | Stop, remove container, delete volume and image |
| `bash aws/scripts/env.sh` | Print five `export` statements (endpoint, credentials, profile) — use with `eval $(...)` |
| `bash aws/scripts/test.sh` | Run S3, SQS, and Lambda smoke tests |
| `bash aws/scripts/test.sh --skip-lambda` | Smoke tests without Lambda |

---

## Docker Compose (alternative)

```bash
# Docker
docker compose -f aws/docker-compose.yml up -d

# Podman
export CONTAINER_SOCK=/var/run/docker.sock
podman-compose -f aws/docker-compose.yml up -d
```

Data is stored in `aws/data/` relative to the project root.

---

## Data Persistence

| Method | How | Survives `stop`? | Survives `teardown --purge`? |
|--------|-----|:---:|:---:|
| Named volume (default) | Automatic — `floci-data` Docker/Podman volume | ✅ | ❌ |
| Custom host directory | `--persist ./data` flag or docker-compose | ✅ | ✅ |

---

## Troubleshooting

### `InvalidClientTokenId` error on any AWS CLI command
You have real AWS credentials in `~/.aws/credentials` that are overriding the Floci test credentials. This happens even when `AWS_ENDPOINT_URL` is set — AWS CLI v1 still uses the credential file.

Run `eval $(bash aws/scripts/env.sh)` which now also exports `AWS_PROFILE=floci` (a profile with `key=test`) to fully override the real profile:
```bash
eval $(bash aws/scripts/env.sh)
```
Then verify all five vars are set:
```bash
echo $AWS_ENDPOINT_URL $AWS_ACCESS_KEY_ID $AWS_PROFILE
# expected: http://localhost:4566 test floci
```

### `aws s3 ls` returns nothing / hits real AWS
The `AWS_ENDPOINT_URL` variable is not set in this terminal. Run:
```bash
eval $(bash aws/scripts/env.sh)
```

### `aws s3 ls bucket` — NoSuchBucket error
The correct syntax is `aws s3 ls s3://bucket-name` (the `s3://` prefix is required):
```bash
aws s3 ls s3://bkt1
```

### Floci UI shows "Connection refused"
The container socket is not mounted correctly. Stop and restart:
```bash
bash aws/scripts/stop.sh && bash aws/scripts/start.sh
```

### View container logs
```bash
# Podman
podman logs -f floci

# Docker
docker logs -f floci
```

### Full reset
```bash
bash aws/scripts/teardown.sh --purge
bash aws/scripts/install.sh
bash aws/scripts/start.sh
```

---

## Endpoint & Credentials Summary

| Setting | Value |
|---------|-------|
| Endpoint | `http://localhost:4566` |
| Access Key ID | `test` |
| Secret Access Key | `test` |
| Default Region | `us-east-1` |
| Web UI | `http://localhost:4566/_floci/ui` |
