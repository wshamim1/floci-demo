#!/usr/bin/env python3
# =============================================================================
# aws/examples/s3/s3_upload.py
#
# A simple Python script using boto3 to upload a sample file to an S3 bucket
# on your local Floci/AWS emulator.
#
# Prerequisites:
#   pip install boto3
#   export AWS_ENDPOINT_URL=http://localhost:4566
# =============================================================================

import os
import boto3
from botocore.exceptions import ClientError

# Configuration
ENDPOINT_URL = os.environ.get("AWS_ENDPOINT_URL", "http://localhost:4566")
BUCKET_NAME = "my-python-bucket"
LOCAL_FILE = "sample.txt"
OBJECT_NAME = "sample-uploaded.txt"

def main():
    print("=== Floci Python S3 Upload Demo ===")
    print(f"Target Endpoint: {ENDPOINT_URL}")
    print(f"Bucket Name:     {BUCKET_NAME}")
    print()

    # 1. Create a local dummy file to upload
    print(f"1. Creating local file: '{LOCAL_FILE}'...")
    with open(LOCAL_FILE, "w") as f:
        f.write("Hello from Python S3 Uploader script! 🐍🚀\n")
        f.write("This file was uploaded to local Floci container.\n")
    print("Local file created successfully.")
    print()

    # 2. Initialise S3 Client
    # We override endpoint_url to point S3 requests to Floci instead of real AWS
    s3_client = boto3.client(
        "s3",
        endpoint_url=ENDPOINT_URL,
        aws_access_key_id="test",
        aws_secret_access_key="test",
        region_name="us-east-1"
    )

    # 3. Create Bucket if it doesn't exist
    print(f"2. Checking if bucket '{BUCKET_NAME}' exists...")
    try:
        s3_client.head_bucket(Bucket=BUCKET_NAME)
        print(f"Bucket '{BUCKET_NAME}' already exists.")
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == '404':
            print(f"Bucket '{BUCKET_NAME}' not found. Creating bucket...")
            s3_client.create_bucket(Bucket=BUCKET_NAME)
            print(f"Bucket '{BUCKET_NAME}' created successfully.")
        else:
            print(f"Error checking bucket: {e}")
            return
    print()

    # 4. Upload File
    print(f"3. Uploading '{LOCAL_FILE}' to s3://{BUCKET_NAME}/{OBJECT_NAME}...")
    try:
        s3_client.upload_file(LOCAL_FILE, BUCKET_NAME, OBJECT_NAME)
        print("Upload completed successfully! 🎉")
    except Exception as e:
        print(f"Error uploading file: {e}")
        return
    print()

    # 5. List objects in bucket to verify
    print(f"4. Listing objects in '{BUCKET_NAME}' to verify:")
    try:
        response = s3_client.list_objects_v2(Bucket=BUCKET_NAME)
        if 'Contents' in response:
            for obj in response['Contents']:
                print(f" - {obj['Key']} ({obj['Size']} bytes)")
        else:
            print("Bucket is empty.")
    except Exception as e:
        print(f"Error listing objects: {e}")
    print()

    # Clean up local file
    if os.path.exists(LOCAL_FILE):
        os.remove(LOCAL_FILE)
        print("5. Local temporary file cleaned up.")
    
    print()
    print("=== Demo Complete ===")

if __name__ == "__main__":
    main()
