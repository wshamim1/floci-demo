# Floci — Local Cloud Emulator

Floci runs local emulators for **AWS**, **Azure**, and **GCP**, letting you develop and test cloud services without touching a real cloud account.

| Cloud | Emulator | Endpoint(s) | Services |
|-------|----------|-------------|---------|
| AWS | LocalStack (Floci) | `http://localhost:4566` | S3, SQS, Lambda, DynamoDB, and more |
| Azure | Azurite | `:10000` / `:10001` / `:10002` | Blob, Queue, Table Storage |
| GCP | fake-gcs-server + Pub/Sub emulator | `:4443` / `:8085` | Cloud Storage, Pub/Sub |

---

## Requirements

| Tool | Minimum version | Notes |
|------|----------------|-------|
| macOS | 12 Monterey+ | arm64 or x86_64 |
| Docker Desktop **or** Podman | Latest stable | One runtime is enough |
| AWS CLI | v2 | `brew install awscli` — for AWS only |
| Azure CLI | Latest | `brew install azure-cli` — for Azure only |
| Google Cloud SDK | Latest | `brew install --cask google-cloud-sdk` — for GCP only |

---

## AWS

### Quick Start

```bash
# 1. Install dependencies (Docker/Podman + AWS CLI + Floci image)
bash aws/scripts/install.sh

# 2. Start Floci
bash aws/scripts/start.sh

# 3. Set environment variables
eval $(bash aws/scripts/env.sh)

# 4. Verify
aws s3 ls
```

Floci will be available at **http://localhost:4566** within ~1 second.

> **Tip — make it permanent:** Add the exports from `eval $(bash aws/scripts/env.sh)` to `~/.zshrc` so they are set automatically in every new terminal.

### AWS CLI Usage

> ⚠️ **Before running any AWS CLI command**, make sure the environment variables are set in your current terminal:
> ```bash
> eval $(bash aws/scripts/env.sh)
> ```

#### S3

```bash
# List all buckets
aws s3 ls

# Create a bucket
aws s3 mb s3://my-bucket

# Upload a file
aws s3 cp ./file.txt s3://my-bucket/file.txt

# List objects  ← note s3://bucket-name, NOT just bucket-name
aws s3 ls s3://my-bucket

# Download a file
aws s3 cp s3://my-bucket/file.txt ./file.txt

# Delete a bucket and all its contents
aws s3 rb s3://my-bucket --force
```

#### SQS

```bash
# Create a queue
aws sqs create-queue --queue-name my-queue

# Send a message
aws sqs send-message --queue-url http://localhost:4566/000000000000/my-queue --message-body "hello"

# Receive a message
aws sqs receive-message --queue-url http://localhost:4566/000000000000/my-queue --max-number-of-messages 1
```

#### DynamoDB

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

#### Lambda

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

### AWS Examples

The [`aws/examples/`](aws/examples/) folder contains self-contained, runnable examples:

| Directory | Service | What it covers |
|-----------|---------|----------------|
| [`aws/examples/configure/`](aws/examples/configure/) | AWS CLI | All three credential/endpoint patterns |
| [`aws/examples/s3/`](aws/examples/s3/) | S3 | Buckets, upload/download, list, delete |
| [`aws/examples/sqs/`](aws/examples/sqs/) | SQS | Queues, single/batch send, receive, delete |
| [`aws/examples/lambda/`](aws/examples/lambda/) | Lambda | Deploy a Node.js function, sync/async invoke |
| [`aws/examples/terraform/`](aws/examples/terraform/) | Terraform | Full `terraform apply` against Floci (S3 + SQS) |

See [`aws/examples/README.md`](aws/examples/README.md) for prerequisites and usage.

### AWS Scripts Reference

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
| `bash aws/scripts/env.sh` | Print five `export` statements — use with `eval $(...)` |
| `bash aws/scripts/test.sh` | Run S3, SQS, and Lambda smoke tests |
| `bash aws/scripts/test.sh --skip-lambda` | Smoke tests without Lambda |

### AWS Endpoint & Credentials Summary

| Setting | Value |
|---------|-------|
| Endpoint | `http://localhost:4566` |
| Access Key ID | `test` |
| Secret Access Key | `test` |
| Default Region | `us-east-1` |
| Web UI | `http://localhost:4566/_floci/ui` |

### Docker Compose (AWS)

```bash
docker compose -f aws/docker-compose.yml up -d
```

Data is stored in `aws/data/` relative to the project root.

---

## Azure

### Quick Start

```bash
# 1. Install dependencies (Docker/Podman + Azure CLI + Azurite image)
bash azure/scripts/install.sh

# 2. Start Azurite
bash azure/scripts/start.sh

# 3. Set environment variables
eval $(bash azure/scripts/env.sh)

# 4. Verify
az storage container list \
  --account-name devstoreaccount1 \
  --blob-endpoint http://127.0.0.1:10000/devstoreaccount1 \
  --account-key Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==
```

### Azure Endpoints & Credentials

Azurite uses a fixed well-known account for local development:

| Setting | Value |
|---------|-------|
| Account Name | `devstoreaccount1` |
| Account Key | `Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==` |
| Blob endpoint | `http://127.0.0.1:10000/devstoreaccount1` |
| Queue endpoint | `http://127.0.0.1:10001/devstoreaccount1` |
| Table endpoint | `http://127.0.0.1:10002/devstoreaccount1` |

### Azure CLI Usage

> ⚠️ **Before running any Azure CLI command**, export the credentials:
> ```bash
> eval $(bash azure/scripts/env.sh)
> ```

#### Blob Storage

```bash
# Create a container
az storage container create \
  --name my-container \
  --account-name $AZURE_STORAGE_ACCOUNT \
  --account-key $AZURE_STORAGE_KEY \
  --blob-endpoint $AZURE_BLOB_ENDPOINT

# Upload a blob
az storage blob upload \
  --container-name my-container \
  --name file.txt \
  --file ./file.txt \
  --account-name $AZURE_STORAGE_ACCOUNT \
  --account-key $AZURE_STORAGE_KEY \
  --blob-endpoint $AZURE_BLOB_ENDPOINT

# List blobs
az storage blob list \
  --container-name my-container \
  --account-name $AZURE_STORAGE_ACCOUNT \
  --account-key $AZURE_STORAGE_KEY \
  --blob-endpoint $AZURE_BLOB_ENDPOINT \
  --output table

# Download a blob
az storage blob download \
  --container-name my-container \
  --name file.txt \
  --file ./file-downloaded.txt \
  --account-name $AZURE_STORAGE_ACCOUNT \
  --account-key $AZURE_STORAGE_KEY \
  --blob-endpoint $AZURE_BLOB_ENDPOINT
```

#### Queue Storage

```bash
# Create a queue
az storage queue create \
  --name my-queue \
  --account-name $AZURE_STORAGE_ACCOUNT \
  --account-key $AZURE_STORAGE_KEY \
  --queue-endpoint $AZURE_QUEUE_ENDPOINT

# Send a message
az storage message put \
  --queue-name my-queue \
  --content "hello world" \
  --account-name $AZURE_STORAGE_ACCOUNT \
  --account-key $AZURE_STORAGE_KEY \
  --queue-endpoint $AZURE_QUEUE_ENDPOINT

# Peek at messages (non-destructive)
az storage message peek \
  --queue-name my-queue \
  --account-name $AZURE_STORAGE_ACCOUNT \
  --account-key $AZURE_STORAGE_KEY \
  --queue-endpoint $AZURE_QUEUE_ENDPOINT
```

#### Table Storage

```bash
# Create a table
az storage table create \
  --name myusers \
  --account-name $AZURE_STORAGE_ACCOUNT \
  --account-key $AZURE_STORAGE_KEY \
  --table-endpoint $AZURE_TABLE_ENDPOINT

# Insert an entity
az storage entity insert \
  --table-name myusers \
  --entity PartitionKey=users RowKey=1 name=Alice \
  --account-name $AZURE_STORAGE_ACCOUNT \
  --account-key $AZURE_STORAGE_KEY \
  --table-endpoint $AZURE_TABLE_ENDPOINT

# Query an entity
az storage entity show \
  --table-name myusers \
  --partition-key users \
  --row-key 1 \
  --account-name $AZURE_STORAGE_ACCOUNT \
  --account-key $AZURE_STORAGE_KEY \
  --table-endpoint $AZURE_TABLE_ENDPOINT
```

### Azure Examples

The [`azure/examples/`](azure/examples/) folder contains self-contained, runnable examples:

| Directory | Service | What it covers |
|-----------|---------|----------------|
| [`azure/examples/blob/`](azure/examples/blob/) | Blob Storage | Containers, upload/download, list, delete |
| [`azure/examples/queue/`](azure/examples/queue/) | Queue Storage | Queues, send/peek/receive messages |
| [`azure/examples/table/`](azure/examples/table/) | Table Storage | Tables, insert/query/delete entities |

See [`azure/examples/README.md`](azure/examples/README.md) for prerequisites and usage.

### Azure Scripts Reference

| Script | Description |
|--------|-------------|
| `bash azure/scripts/install.sh` | Install Homebrew, container runtime, Azure CLI, and pull the Azurite image |
| `bash azure/scripts/install.sh --docker` | Force Docker Desktop |
| `bash azure/scripts/install.sh --podman` | Force Podman |
| `bash azure/scripts/start.sh` | Start the Azurite container |
| `bash azure/scripts/start.sh --persist ./data` | Start with a custom host directory for persistence |
| `bash azure/scripts/stop.sh` | Stop the container (data is preserved) |
| `bash azure/scripts/teardown.sh` | Stop and remove the container (data preserved) |
| `bash azure/scripts/teardown.sh --purge` | Stop, remove container, delete volume and image |
| `bash azure/scripts/env.sh` | Print `export` statements — use with `eval $(...)` |
| `bash azure/scripts/test.sh` | Run Blob, Queue, and Table smoke tests |

### Docker Compose (Azure)

```bash
docker compose -f azure/docker-compose.yml up -d
```

Data is stored in `azure/data/` relative to the project root.

---

## GCP

### Quick Start

```bash
# 1. Install dependencies (Docker/Podman + Google Cloud SDK + emulator images)
bash gcp/scripts/install.sh

# 2. Start GCS + Pub/Sub emulators
bash gcp/scripts/start.sh

# 3. Set environment variables
eval $(bash gcp/scripts/env.sh)

# 4. Verify GCS
curl http://localhost:4443/storage/v1/b?project=floci-project

# 5. Verify Pub/Sub
curl http://localhost:8085/v1/projects/floci-project/topics
```

Both emulators start independently. Use `--gcs-only` or `--pubsub-only` to start just one.

### GCP Endpoints & Credentials

GCP emulators do not require real credentials — any project ID works.

| Service | Endpoint | Environment variable |
|---------|----------|---------------------|
| Cloud Storage (GCS) | `http://localhost:4443` | `STORAGE_EMULATOR_HOST` |
| Pub/Sub | `localhost:8085` | `PUBSUB_EMULATOR_HOST` |
| Project ID | `floci-project` | `GOOGLE_CLOUD_PROJECT` |

### GCS Usage (via REST API)

```bash
# List buckets
curl http://localhost:4443/storage/v1/b?project=floci-project

# Create a bucket
curl -X POST http://localhost:4443/storage/v1/b?project=floci-project \
  -H "Content-Type: application/json" \
  -d '{"name":"my-bucket"}'

# Upload an object
curl -X POST \
  "http://localhost:4443/upload/storage/v1/b/my-bucket/o?uploadType=media&name=hello.txt" \
  -H "Content-Type: text/plain" \
  --data-binary "Hello from Floci GCP!"

# Download an object
curl "http://localhost:4443/storage/v1/b/my-bucket/o/hello.txt?alt=media"

# Delete an object
curl -X DELETE "http://localhost:4443/storage/v1/b/my-bucket/o/hello.txt"

# Delete a bucket
curl -X DELETE "http://localhost:4443/storage/v1/b/my-bucket"
```

### Pub/Sub Usage (via REST API)

```bash
PROJECT=floci-project
BASE=http://localhost:8085

# Create a topic
curl -X PUT "$BASE/v1/projects/$PROJECT/topics/my-topic" \
  -H "Content-Type: application/json" -d '{}'

# Create a subscription
curl -X PUT "$BASE/v1/projects/$PROJECT/subscriptions/my-sub" \
  -H "Content-Type: application/json" \
  -d "{\"topic\":\"projects/$PROJECT/topics/my-topic\"}"

# Publish a message (data must be base64-encoded)
MSG=$(echo -n "Hello from Floci!" | base64)
curl -X POST "$BASE/v1/projects/$PROJECT/topics/my-topic:publish" \
  -H "Content-Type: application/json" \
  -d "{\"messages\":[{\"data\":\"$MSG\"}]}"

# Pull messages
curl -X POST "$BASE/v1/projects/$PROJECT/subscriptions/my-sub:pull" \
  -H "Content-Type: application/json" \
  -d '{"maxMessages":1}'
```

### GCP Examples

The [`gcp/examples/`](gcp/examples/) folder contains self-contained, runnable examples:

| Directory | Service | What it covers |
|-----------|---------|----------------|
| [`gcp/examples/gcs/`](gcp/examples/gcs/) | Cloud Storage (GCS) | Buckets, upload/download, list, delete |
| [`gcp/examples/pubsub/`](gcp/examples/pubsub/) | Pub/Sub | Topics, subscriptions, publish, pull, ack |

See [`gcp/examples/README.md`](gcp/examples/README.md) for prerequisites and usage.

### GCP Scripts Reference

| Script | Description |
|--------|-------------|
| `bash gcp/scripts/install.sh` | Install Homebrew, container runtime, Google Cloud SDK, and pull emulator images |
| `bash gcp/scripts/install.sh --docker` | Force Docker Desktop |
| `bash gcp/scripts/install.sh --podman` | Force Podman |
| `bash gcp/scripts/start.sh` | Start GCS + Pub/Sub emulators |
| `bash gcp/scripts/start.sh --gcs-only` | Start GCS emulator only |
| `bash gcp/scripts/start.sh --pubsub-only` | Start Pub/Sub emulator only |
| `bash gcp/scripts/stop.sh` | Stop all GCP emulators (data is preserved) |
| `bash gcp/scripts/stop.sh --gcs-only` | Stop GCS emulator only |
| `bash gcp/scripts/stop.sh --pubsub-only` | Stop Pub/Sub emulator only |
| `bash gcp/scripts/teardown.sh` | Stop and remove containers (data preserved) |
| `bash gcp/scripts/teardown.sh --purge` | Stop, remove containers, delete volumes and images |
| `bash gcp/scripts/env.sh` | Print `export` statements — use with `eval $(...)` |
| `bash gcp/scripts/test.sh` | Run GCS and Pub/Sub smoke tests |
| `bash gcp/scripts/test.sh --skip-pubsub` | Smoke tests without Pub/Sub |

### Docker Compose (GCP)

```bash
docker compose -f gcp/docker-compose.yml up -d
```

GCS data is stored in the `floci-gcs-data` named volume. Pub/Sub state is in-memory and resets on restart.

---

## Data Persistence

| Cloud | Method | Survives `stop`? | Survives `teardown --purge`? |
|-------|--------|:---:|:---:|
| AWS | Named volume `floci-data` (default) | ✅ | ❌ |
| AWS | Custom host dir `--persist ./data` | ✅ | ✅ |
| Azure | Named volume `floci-azure-data` (default) | ✅ | ❌ |
| Azure | Custom host dir `--persist ./data` | ✅ | ✅ |
| GCP (GCS) | Named volume `floci-gcs-data` | ✅ | ❌ |
| GCP (Pub/Sub) | In-memory only | ❌ | ❌ |

---

## Troubleshooting

### AWS: `InvalidClientTokenId` error
You have real AWS credentials in `~/.aws/credentials` overriding Floci test credentials. Run:
```bash
eval $(bash aws/scripts/env.sh)
```
Then verify:
```bash
echo $AWS_ENDPOINT_URL $AWS_ACCESS_KEY_ID $AWS_PROFILE
# expected: http://localhost:4566 test floci
```

### AWS: `aws s3 ls` returns nothing / hits real AWS
The `AWS_ENDPOINT_URL` variable is not set. Run:
```bash
eval $(bash aws/scripts/env.sh)
```

### Azure: `ResourceNotFound` or connection refused
The Azurite container is not running. Start it:
```bash
bash azure/scripts/start.sh
```
Then verify:
```bash
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:10000/devstoreaccount1
# expected: 400 (Azurite is up but the bare GET is malformed — that's normal)
```

### GCP: GCS returns connection refused
The GCS emulator is not running. Start it:
```bash
bash gcp/scripts/start.sh --gcs-only
```
Then verify:
```bash
curl http://localhost:4443/storage/v1/b?project=floci-project
# expected: {"kind":"storage#buckets"} or similar JSON
```

### GCP: Pub/Sub returns connection refused
The Pub/Sub emulator may take up to 10 seconds to initialise. Check the logs:
```bash
docker logs floci-pubsub
```
Or restart:
```bash
bash gcp/scripts/stop.sh --pubsub-only && bash gcp/scripts/start.sh --pubsub-only
```

### View container logs

```bash
# AWS
docker logs -f floci

# Azure
docker logs -f floci-azure

# GCP
docker logs -f floci-gcs
docker logs -f floci-pubsub
```

### Full reset

```bash
# AWS
bash aws/scripts/teardown.sh --purge && bash aws/scripts/install.sh && bash aws/scripts/start.sh

# Azure
bash azure/scripts/teardown.sh --purge && bash azure/scripts/install.sh && bash azure/scripts/start.sh

# GCP
bash gcp/scripts/teardown.sh --purge && bash gcp/scripts/install.sh && bash gcp/scripts/start.sh
```
