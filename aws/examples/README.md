# Floci Examples

Practical, runnable examples for every supported service. Each subdirectory is self-contained — follow the steps in order and they will work against a running Floci instance (`http://localhost:4566`).

## Prerequisites

Start Floci before running any example:

```bash
bash ../scripts/start.sh
```

Then configure the AWS CLI once:

```bash
# Any credentials work — Floci does not validate them
aws configure set aws_access_key_id floci
aws configure set aws_secret_access_key floci
aws configure set region us-east-1

# Point every command at Floci automatically
export AWS_ENDPOINT_URL=http://localhost:4566
```

---

## Examples

| Directory | Service | What it covers |
|-----------|---------|----------------|
| [`configure/`](configure/) | AWS CLI | All three ways to point the CLI at Floci |
| [`s3/`](s3/) | S3 | Buckets, objects, upload/download |
| [`sqs/`](sqs/) | SQS | Queues, send/receive messages, batch ops |
| [`dynamodb/`](dynamodb/) | DynamoDB | Tables, put/get items, scan, cleanup |
| [`secretsmanager/`](secretsmanager/) | Secrets Manager | Secrets, create/get values, list, delete |
| [`lambda/`](lambda/) | Lambda | Deploy a Node.js function, invoke sync/async |
| [`terraform/`](terraform/) | Terraform + S3/SQS | Full `terraform apply` against Floci |

---

## Running the shell examples

Every `*.sh` file in the service subdirectories can be run directly:

```bash
# Make sure Floci is running and AWS_ENDPOINT_URL is exported, then:
bash aws/examples/s3/s3_demo.sh
bash aws/examples/sqs/sqs_demo.sh
bash aws/examples/dynamodb/dynamodb_demo.sh
bash aws/examples/secretsmanager/secretsmanager_demo.sh
bash aws/examples/lambda/lambda_demo.sh
```

The Terraform example has its own instructions in [`terraform/README.md`](terraform/README.md).
