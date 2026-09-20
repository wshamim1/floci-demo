# Floci GCP Examples

Practical, runnable examples for GCP emulator services. Each subdirectory is self-contained — follow the steps in order and they will work against running local emulators.

## Prerequisites

Start the GCP emulators before running any example:

```bash
bash gcp/scripts/start.sh
```

Then export the environment variables:

```bash
eval $(bash gcp/scripts/env.sh)
```

This sets:

| Variable | Value |
|----------|-------|
| `STORAGE_EMULATOR_HOST` | `http://localhost:4443` |
| `PUBSUB_EMULATOR_HOST` | `localhost:8085` |
| `GOOGLE_CLOUD_PROJECT` | `floci-project` |
| `PUBSUB_PROJECT_ID` | `floci-project` |

---

## Examples

| Directory | Service | What it covers |
|-----------|---------|----------------|
| [`gcs/`](gcs/) | Cloud Storage (GCS) | Buckets, upload/download, list, delete |
| [`pubsub/`](pubsub/) | Pub/Sub | Topics, subscriptions, publish, pull, ack |

---

## Running the examples

```bash
bash gcp/examples/gcs/gcs_demo.sh
bash gcp/examples/pubsub/pubsub_demo.sh
```

Both scripts use the GCS/Pub/Sub **REST API via `curl`** — no gcloud credentials setup is needed.
