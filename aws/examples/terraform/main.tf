terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Provider — points every service at the local Floci endpoint.
# Floci accepts any credentials and skips all AWS-side validation.
# ──────────────────────────────────────────────────────────────────────────────
provider "aws" {
  region     = "us-east-1"
  access_key = "floci"
  secret_key = "floci"

  # Route each service to the local Floci endpoint
  endpoints {
    s3     = "http://localhost:4566"
    sqs    = "http://localhost:4566"
    lambda = "http://localhost:4566"
    iam    = "http://localhost:4566"
  }

  # Skip validations that require a real AWS account
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  skip_region_validation      = true

  # Required for path-style S3 access (Floci does not support virtual-hosted style)
  s3_use_path_style = true
}

# ──────────────────────────────────────────────────────────────────────────────
# Random suffix — keeps the bucket name unique across runs
# ──────────────────────────────────────────────────────────────────────────────
resource "random_id" "suffix" {
  byte_length = 4
}

# ──────────────────────────────────────────────────────────────────────────────
# S3 Bucket
# ──────────────────────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "storage" {
  bucket        = "floci-terraform-demo-${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# SQS Queue
# ──────────────────────────────────────────────────────────────────────────────
resource "aws_sqs_queue" "jobs" {
  name                      = "floci-jobs-${random_id.suffix.hex}"
  message_retention_seconds = 86400 # 1 day
  visibility_timeout_seconds = 30
}

# ──────────────────────────────────────────────────────────────────────────────
# Outputs
# ──────────────────────────────────────────────────────────────────────────────
output "bucket_name" {
  description = "Name of the S3 bucket created in Floci"
  value       = aws_s3_bucket.storage.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.storage.arn
}

output "queue_url" {
  description = "URL of the SQS queue created in Floci"
  value       = aws_sqs_queue.jobs.url
}
