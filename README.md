# betops-infra

Infrastructure for the sportsbook agent platform. One GCP project, Terraform for the cloud pieces, plain Kubernetes manifests with kustomize for the cluster, and a compose file for local wiring. There is no application code here.

## Topology

```
 webhooks / feeds                         scheduler (every 5 min, daily)
        |                                          |
        v                                          v
 +--------------+   +---------------------------------------------+
 | Cloud        |-->|                  Pub/Sub                    |
 | Functions    |   | sports-news  bet-settlements  feed-events   |
 | (gen2)       |   | placement-orders   (each has a DLQ topic)   |
 +--------------+   +----------------------+----------------------+
                                           |
                                           v
                    +----------------------+----------------------+
                    |                     GKE                     |
                    |  pulse-agents   vip-concierge   scoring     |
                    |  general pool                               |
                    |  vllm (statefulset, L4 gpu pool)            |
                    +----------+----------------------+-----------+
                               |                      |
                               v                      v
                       Cloud Tasks queue        Cloud Run
                       placement-dispatch       player-replies
                       (50/s, 20 in flight)     (0 to 20 instances)
                               |
                               v
                         betting engine
```

## Why compute matches traffic shape

- GKE runs what has to stay warm. The agents hold Pub/Sub streaming pulls and in memory state like thread cooldowns and circuit breakers. Scale to zero would drop both. vllm sits on its own GPU pool because a model load takes minutes and the pool can scale to zero nodes when nobody needs it.
- Cloud Run runs request shaped work. Player replies arrive in bursts around match events and then stop. Scale to zero with concurrency 80 costs nothing while idle.
- Cloud Functions run webhook ingestion. Each call is short, stateless and verifies a signature, then publishes one message. Ingress is limited to internal traffic and the load balancer.
- Cloud Scheduler publishes to Pub/Sub instead of calling services, so a slow consumer never makes a cron job fail.

## How DLQs and rate limits protect the engine

Every topic has a dead letter topic. The main subscription gives up after 5 delivery attempts, with exponential backoff from 5 seconds to 5 minutes between tries. A poison message lands in the DLQ with its attributes intact, and an alert fires when any DLQ subscription holds a message. Nothing blocks the rest of the stream.

Bet placement goes through the Cloud Tasks queue `placement-dispatch`. It caps dispatch at 50 per second and 20 concurrent calls, and retries with doubling backoff for up to 15 minutes. A burst of agent decisions turns into a steady flow, so the betting engine sees a flat load. The same number is set as `PLACEMENT_RATE_PER_SECOND` in the agents config, so the client side limiter and the queue agree.

## Layout

- `terraform/` holds the network, GKE, messaging, serverless, IAM, secrets and monitoring. Secret Manager entries are names only. Values are added out of band.
- `k8s/base/` has one folder per workload. `k8s/overlays/prod` patches replicas and resources.
- The workloads read secrets from a Kubernetes secret named `platform-secrets`. Sync it from Secret Manager with whichever operator the cluster uses.
- `vercel/` deploys the static eval report.
- `.github/workflows/deploy-example.yml` is manual only. It plans, then applies behind a protected environment.

## Validate locally

No cloud credentials are needed.

```
cd terraform
terraform fmt -check -recursive
terraform init -backend=false
terraform validate

cd ..
kustomize build k8s/overlays/prod | kubeconform -strict -summary -kubernetes-version 1.30.0
```

Never run plan or apply from a laptop. The deploy workflow owns that.

## Run the services locally

```
docker compose up --build
```

The compose file expects the sibling repos `pulse-agents`, `pulse-vip-concierge`, `agentloop` and `sportsbook-contracts` next to this folder. It starts the Pub/Sub emulator, Postgres, Redis, both node services and the scoring sidecar. The scoring container installs from source and trains the fixture model on start, since that sidecar has no Dockerfile of its own. Model keys in the example env files are placeholders, so calls to model providers fail until you set real ones.

## Known gaps

- The agents also subscribe to mention and direct message topics that the Terraform here does not create yet.
