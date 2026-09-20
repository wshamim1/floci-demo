#!/usr/bin/env python3
# =============================================================================
# aws/examples/sqs/sqs_read.py
#
# A continuous Python SQS message receiver/listener using boto3.
# It keeps running, polling local SQS on port 4566, so you can post 
# messages from your Web UI (StackPort) and see them instantly in your terminal!
#
# Prerequisites:
#   pip install boto3
#   export AWS_ENDPOINT_URL=http://localhost:4566
# =============================================================================

import os
import sys
import boto3
from botocore.exceptions import ClientError

# Configuration
ENDPOINT_URL = os.environ.get("AWS_ENDPOINT_URL", "http://localhost:4566")
QUEUE_NAME = "my-python-queue"

def main():
    print("=== Floci Python SQS Continuous Receiver ===")
    print(f"Target Endpoint: {ENDPOINT_URL}")
    print(f"Queue Name:      {QUEUE_NAME}")
    print()

    # 1. Initialise SQS Client
    sqs_client = boto3.client(
        "sqs",
        endpoint_url=ENDPOINT_URL,
        aws_access_key_id="test",
        aws_secret_access_key="test",
        region_name="us-east-1"
    )

    # 2. Get or Create SQS Queue
    try:
        response = sqs_client.get_queue_url(QueueName=QUEUE_NAME)
        queue_url = response['QueueUrl']
        print(f"Queue URL: {queue_url}")
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code in ['AWS.SimpleQueueService.NonExistentQueue', 'QueueDoesNotExist']:
            print(f"Queue '{QUEUE_NAME}' not found. Creating queue...")
            create_response = sqs_client.create_queue(QueueName=QUEUE_NAME)
            queue_url = create_response['QueueUrl']
            print(f"Queue created successfully! URL: {queue_url}")
        else:
            print(f"Error checking queue: {e}")
            return
    print()

    print("==================================================")
    print(f" 📥 Listening for messages in '{QUEUE_NAME}'...")
    print(" Feel free to post a message from StackPort UI!")
    print(" Press Ctrl+C to stop the receiver.")
    print("==================================================")
    print()

    try:
        while True:
            # Poll with SQS Long Polling (WaitTimeSeconds=10) to reduce CPU usage
            receive_response = sqs_client.receive_message(
                QueueUrl=queue_url,
                MaxNumberOfMessages=5,      # Fetch up to 5 messages at once
                WaitTimeSeconds=10,         # Long polling (10 seconds wait)
                MessageAttributeNames=['All']
            )
            
            messages = receive_response.get('Messages', [])
            if messages:
                for msg in messages:
                    print("📬 [RECEIVED MESSAGE]")
                    print(f" - Message ID:   {msg.get('MessageId')}")
                    print(f" - Body:         {msg.get('Body')}")
                    
                    # Print attributes if present
                    attrs = msg.get('MessageAttributes', {})
                    if attrs:
                        print(" - Attributes:")
                        for attr_name, attr_val in attrs.items():
                            print(f"    * {attr_name}: {attr_val.get('StringValue')}")
                    
                    # Delete message (acknowledgement) so SQS clears it
                    sqs_client.delete_message(
                        QueueUrl=queue_url,
                        ReceiptHandle=msg.get('ReceiptHandle')
                    )
                    print(" - Status:       Processed & Deleted successfully.")
                    print()
            else:
                # No messages in this polling cycle
                print(".", end="", flush=True)  # Print a dot to show we are actively waiting
                
    except KeyboardInterrupt:
        print("\nStopping SQS Receiver. Bye! 👋")
        sys.exit(0)
    except Exception as e:
        print(f"\nError occurred: {e}")

if __name__ == "__main__":
    main()
