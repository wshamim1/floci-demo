# Terraform + Floci Example

This example runs a full `terraform apply` against a local Floci instance. No AWS account, no credentials, no cost.

Floci implements the same wire protocol as the AWS REST APIs. Terraform's `hashicorp/aws` provider sends a `CreateBucket` request and Floci returns the exact XML response AWS would. Terraform cannot distinguish the two.

---

## What gets created

| Resource | Type | Notes |
|----------|------|-------|
| `aws_s3_bucket.storage` | S3 bucket | Name includes a random 4-byte hex suffix |
| `aws_s3_bucket_versioning.storage` | S3 versioning | Enabled |
| `aws_sqs_queue.jobs` | SQS standard queue | 1-day retention, 30-s visibility timeout |

---

## Prerequisites

| Tool | Minimum version |
|------|----------------|
| Terraform | 1.6+ |
| Floci | running on `http://localhost:4566` |

Start Floci first:

```bash
bash aws/scripts/start.sh
```

---

## Usage

```bash
cd examples/terraform

# Download providers (~200 MB on first run)
terraform init

# Preview what will be created
terraform plan

# Create all resources in Floci
terraform apply

# Verify with the AWS CLI
aws s3 ls --endpoint-url=http://localhost:4566
aws sqs list-queues --endpoint-url=http://localhost:4566

# Destroy everything when done
terraform destroy
```

Expected `terraform apply` output (abridged):

```
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

bucket_name = "floci-terraform-demo-a1b2c3d4"
bucket_arn  = "arn:aws:s3:::floci-terraform-demo-a1b2c3d4"
queue_url   = "http://localhost:4566/000000000000/floci-jobs-a1b2c3d4"
```

---

## How the provider is configured

The key settings in [`main.tf`](main.tf) that make Terraform work with Floci:

```hcl
provider "aws" {
  access_key = "floci"          # Any value — Floci does not validate credentials
  secret_key = "floci"

  endpoints {                   # Override every service endpoint
    s3     = "http://localhost:4566"
    sqs    = "http://localhost:4566"
    lambda = "http://localhost:4566"
    iam    = "http://localhost:4566"
  }

  skip_credentials_validation = true   # No real AWS account to validate against
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  s3_use_path_style           = true   # Floci requires path-style S3 URLs
}
```

None of these settings are Floci-specific — the same configuration works with LocalStack.
