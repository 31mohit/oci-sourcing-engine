# Mini Sourcing Engine on OCI

A deliberately thin candidate-ranking app designed to run like a production system on Oracle Cloud Infrastructure (OCI) to demonstrate Cloud Operations Engineer capabilities.

Status: runs locally with Docker Compose. OCI infrastructure and deployment are in progress (Phase 3 next).

The core deliverable of this project is the **operations layer** surrounding the workload: Infrastructure as Code (Terraform), container orchestration (Docker Compose), CI/CD (GitHub Actions), observability (Prometheus & Grafana), security (least-privilege IAM, Vault secrets), backup/restore, and incident management with a documented postmortem.

---

## Architecture

```
                       ┌─────────────────────────┐
                       │   Client / Recruiter    │
                       └────────────┬────────────┘
                                    │ HTTP (:8000)
                                    ▼
                       ┌─────────────────────────┐
                       │       FastAPI API       │
                       │          (api)          │
                       └──────┬───────────▲──────┘
      POST /jobs:             │           │  GET /jobs/{id}:
      - HSET job:{id}         │           │  - HGETALL job:{id}
      - RPUSH queue:ranking   │           │
                              ▼           │
                       ┌─────────────────────────┐
                       │          Redis          │
                       │      (queue:ranking     │
                       │       + job hashes)     │
                       └────────────┬────────────┘
                                    │
                                    │ BLPOP queue:ranking (5s timeout)
                                    │ HSET job:{id} status="running"|"done"|"failed"
                                    ▼
                       ┌─────────────────────────┐
                       │     Ranking Worker      │
                       │        (worker)         │
                       └─────────────────────────┘
```

- **`api`**: FastAPI service exposing `/health` (verifies Redis connectivity), `POST /jobs` (enqueues ranking jobs, returns HTTP 202), and `GET /jobs/{job_id}` (retrieves job status and ranking results).
- **`redis`**: In-memory broker managing the `queue:ranking` FIFO list and storing no persistence guarantees yet `job:{id}` state hashes with 24-hour expiration.
- **`worker`**: Python background worker that performs blocking pops on `queue:ranking`, sets job status, executes the candidate ranking logic (`ranker.py`), and records results or errors.

---

## Quickstart

### Prerequisites
- Docker and Docker Compose
- Python 3.11+ (for running scripts locally)

### 1. Run the Stack
Start the API, Worker, and Redis services locally:
```bash
docker compose up -d --build
```

The API will be available at `http://localhost:8000`. Verify system health:
```bash
curl http://localhost:8000/health
# {"status":"ok","redis":"ok"}
```

### 2. Run the Unit Tests
Run the ranker unit test suite inside a transient Python 3.11 container:
```bash
docker run --rm -v "${PWD}/app:/app" -w /app python:3.11-slim sh -c "pip install -q -r requirements-dev.txt && pytest -q"
```

### 3. Run the End-to-End Test
With the Docker Compose stack running, execute the end-to-end integration test:
```bash
python scripts/e2e_test.py
```
This script verifies `/health`, loads `data/resumes.json`, submits a ranking job, polls until completion, and asserts response schema, sorting, and limit invariants.

---

## Repository Layout

```
oci-sourcing-engine/
├── app/
│   ├── Dockerfile              # Python 3.11 slim container definition
│   ├── main.py                 # FastAPI application (/health, /jobs)
│   ├── ranker.py               # Pure keyword ranking function
│   ├── worker.py               # Queue consumer and job processor
│   ├── test_ranker.py          # Pytest suite for ranking logic
│   ├── requirements.txt        # Production dependencies (fastapi, uvicorn, redis)
│   └── requirements-dev.txt    # Development/testing dependencies (pytest)
├── data/
│   └── resumes.json            # 50 deterministically generated synthetic resumes
├── docs/
│   └── PRD.md                  # Project requirements, architecture & phase plan
├── monitoring/                 # Prometheus and Grafana configurations (Phase 5)
├── scripts/
│   ├── generate_resumes.py     # Deterministic synthetic resume generator
│   └── e2e_test.py             # End-to-end integration test runner
├── terraform/                  # OCI infrastructure as code (Phase 3)
├── docker-compose.yml          # Multi-container orchestration (api, worker, redis)
├── AGENTS.md                   # Operational boundaries and project rules
└── README.md                   # Project overview and instructions
```

---

## Phased Delivery Status

| Phase | Description | Status |
|---|---|---|
| **1. Setup** | OCI account, budget alert, repository setup, OCI CLI | **Complete** |
| **2. Stub app** | FastAPI service, Redis queue, worker, synthetic resumes, containerization | **Complete** |
| **3. Infrastructure** | Terraform for VCN, subnets, VM, Object Storage, Vault | Not Started |
| **4. Deployment** | GitHub Actions CI/CD pipeline and deployment with rollback | Not Started |
| **5. Monitoring and alerting** | Prometheus, Grafana dashboard, OCI alarms | Not Started |
| **6. Reliability and security** | Retries, idempotency, Vault secrets, backup and restore | Not Started |
| **7. Incident drill** | Simulated outage, runbook execution, postmortem | Not Started |
| **8. App improvements** | Embeddings ranker, feedback loop, outreach drafts | Not Started |
| **9. Portfolio package** | Final documentation, architecture diagram, screenshots | Not Started |

---

## Limitations

- **Synthetic Data Only**: All resumes are generated synthetically; no real candidate data or PII is used.
- **Placeholder Keyword Ranker**: Candidates are scored purely on keyword overlap fraction; no claims of ranking accuracy, quality, or fairness are made. A human reviews and approves all hiring decisions.
- **No Authentication**: The API currently has no multi-tenant authentication or authorization layer.
- **No Persistence Guarantees Yet**: Redis operates as an in-memory queue and cache with 24-hour hash expiration; managed database persistence and backups will be introduced in subsequent infrastructure phases.
