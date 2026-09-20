# Floci Azure Examples

Practical, runnable examples for Azure Storage services. Each subdirectory is self-contained — follow the steps in order and they will work against a running Azurite instance.

## Prerequisites

Start Azurite before running any example:

```bash
bash azure/scripts/start.sh
```

Then export the connection credentials:

```bash
eval $(bash azure/scripts/env.sh)
```

This sets:

| Variable | Value |
|----------|-------|
| `AZURE_STORAGE_ACCOUNT` | `devstoreaccount1` |
| `AZURE_STORAGE_KEY` | Azurite well-known key |
| `AZURE_STORAGE_CONNECTION_STRING` | Full connection string |
| `AZURE_BLOB_ENDPOINT` | `http://127.0.0.1:10000/devstoreaccount1` |
| `AZURE_QUEUE_ENDPOINT` | `http://127.0.0.1:10001/devstoreaccount1` |
| `AZURE_TABLE_ENDPOINT` | `http://127.0.0.1:10002/devstoreaccount1` |

---

## Examples

| Directory | Service | What it covers |
|-----------|---------|----------------|
| [`blob/`](blob/) | Blob Storage | Containers, upload/download, list, delete |
| [`queue/`](queue/) | Queue Storage | Queues, send/peek/receive messages |
| [`table/`](table/) | Table Storage | Tables, insert/query/delete entities |

---

## Running the examples

```bash
bash azure/examples/blob/blob_demo.sh
bash azure/examples/queue/queue_demo.sh
bash azure/examples/table/table_demo.sh
```
