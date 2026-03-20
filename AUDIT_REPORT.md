# Repository Audit Report

**Date:** 2026-03-19
**Branch:** sani-review
**Scope:** Bugs, security issues, architecture problems, Docker/DevOps issues, CI/CD risks (Jenkins)

---

## CRITICAL

### C1 — Missing `path` import in `result/server.js` (Runtime Crash)
**File:** `result/server.js:71`
`res.sendFile(path.resolve(__dirname + "/views/index.html"))` — `path` is used but never imported with `require('path')`. Every GET `/` will throw a `ReferenceError`, making the result service completely broken in production.

### C2 — Hardcoded Database Credentials Everywhere
**Files:**
- `docker-compose.yml:67-68` — `POSTGRES_USER/PASSWORD: "postgres"`
- `worker/Program.cs:19` — `"Server=db;Username=postgres;Password=postgres;"`
- `result/server.js:21` — `"postgres://postgres:postgres@db/postgres"`
- `k8s-specifications/db-deployment.yaml:23-24` — plain-text in YAML
- `result/docker-compose.test.yml:49-51`

Credentials are in source control, visible to anyone. Should use environment variables + Kubernetes Secrets / Docker secrets.

### C3 — Docker Socket Mounted into Containers
**Files:** `trivy-scan.sh:15-37`, `docker-compose.trivy.yml:9`
`-v /var/run/docker.sock:/var/run/docker.sock` gives the container full control of the Docker daemon. A compromised container becomes a full host compromise.

### C4 — Jenkinsfile `|| true` Suppresses All Failures
**File:** `Jenkinsfile` (lines ~46, 64, 73, 82, 92)
Every critical step — linting, static analysis, security scanning — is suffixed with `|| true`. The pipeline will show green even when checks fail. Defeats the entire purpose of CI gates.

### C5 — PostgreSQL `emptyDir` in Kubernetes (Data Loss)
**Files:** `k8s-specifications/db-deployment.yaml:33`, `k8s-specifications/redis-deployment.yaml:28`
```yaml
volumes:
- name: db-data
  emptyDir: {}  # wiped on every pod restart
```
All vote data is permanently lost on any pod restart or eviction. Needs a `PersistentVolumeClaim`.

---

## MEDIUM

### M1 — Flask Debug Mode in Production
**File:** `vote/app.py:53`
```python
app.run(host='0.0.0.0', port=80, debug=True, threaded=True)
```
`debug=True` enables the Werkzeug interactive debugger — arbitrary code execution from the browser. Should use gunicorn (already in `requirements.txt`).

### M2 — No USER Directive in Any Dockerfile
**Files:** `vote/Dockerfile`, `result/Dockerfile`, `worker/Dockerfile`, `seed-data/Dockerfile`
All containers run as root. A container escape grants full host access. Add `USER nobody` or create a dedicated user.

### M3 — Unpinned Base Images
**Files:** All Dockerfiles use tags like `python:3.11-slim`, `node:18-slim`, `mcr.microsoft.com/dotnet/sdk:7.0` — no SHA digest pinning. Builds are non-reproducible and silently pick up upstream changes.

### M4 — `result/tests/Dockerfile` Uses Node 8 (EOL 2019)
**File:** `result/tests/Dockerfile:1` — `node:8.9-slim`. Critical CVEs, no patches. Upgrade to Node 18+.

### M5 — Test PostgreSQL Version Mismatch
**File:** `result/docker-compose.test.yml:48` uses `postgres:9.4` (EOL 2021).
**Production:** `docker-compose.yml` uses `postgres:15-alpine`. Tests don't reflect production behavior.

### M6 — Jenkinsfile Artifacts Reference Non-Existent Paths
**File:** `Jenkinsfile:134-135`
```groovy
'result/dist/**/*'   // no dist/ directory in result service
'vote/build/**/*'    // no build/ directory in vote service
```
Archive steps silently do nothing. No build output is preserved.

### M7 — JUnit Report Format Mismatch
**File:** `Jenkinsfile:137` — `junit testResults: 'result/tests/test-report.txt'`
`result/tests/tests.sh` writes plain text (`echo "Tests passed" >> test-report.txt`), not JUnit XML. Jenkins will fail or silently skip the report.

### M8 — Worker Has No Graceful Shutdown
**File:** `worker/Program.cs:29-61` — `while(true)` loop with no `CancellationToken` or SIGTERM handler. Rolling deployments will SIGKILL the worker mid-vote, potentially losing votes in transit.

### M9 — No Resource Limits Anywhere
**Files:** All `docker-compose.yml` services, all `k8s-specifications/*.yaml`
No memory or CPU limits. A single misbehaving container can starve the host.

### M10 — No Liveness/Readiness Probes in Kubernetes
**Files:** All `k8s-specifications/*-deployment.yaml`
Kubernetes cannot detect unhealthy pods; broken instances stay in rotation and receive traffic.

### M11 — Nginx Has No HTTPS, No Security Headers, No Rate Limiting
**File:** `nginx/nginx.conf`
- HTTP only (port 80), all traffic in plaintext
- Missing: `X-Frame-Options`, `X-Content-Type-Options`, `Content-Security-Policy`, HSTS
- No `limit_req` — open to abuse/DDoS

### M12 — Duplicate Build Stages in Jenkinsfile
**File:** `Jenkinsfile` — images are built once serially (lines ~30-38) then rebuilt again in a "parallel" stage (lines ~94-115). Wasted CI time and ambiguity about which artifact is tested.

### M13 — No `.dockerignore` Files
No `.dockerignore` found in any service directory. `.git`, `node_modules`, test files, and local configs are copied into images — larger images and potential secret leakage.

### M14 — Dependabot Only Covers GitHub Actions
**File:** `.github/dependabot.yml` — only `github-actions` ecosystem monitored. `npm`, `pip`, and `nuget` packages are unmonitored for CVEs.

---

## LOW

### L1 — Hardcoded Service Hostnames
`result/server.js:21` and `worker/Program.cs:19` hardcode the hostname `db`. These are not configurable via environment variables, making multi-environment deployments fragile.

### L2 — `nodemon` in Production Result Image
**File:** `result/Dockerfile:11` — `nodemon` installed globally in the production image. Development tool adds unnecessary attack surface.

### L3 — Git Short SHA as Image Tag
**File:** `Jenkinsfile:22-26` — 7-character short SHAs have collision risk in large repos and are not immutable identifiers for production traceability.

### L4 — Single Replica for All Kubernetes Deployments
All `k8s-specifications/*-deployment.yaml` set `replicas: 1`. Any pod failure causes downtime. Vote and Result services should be at ≥2.

### L5 — No Kubernetes Namespace
All K8s specs deploy to `default` namespace — no isolation, no RBAC scoping possible.

### L6 — `chmod +x` on Every Pipeline Run
**File:** `Jenkinsfile` — scripts have `chmod +x` applied each run rather than committing the executable bit with `git update-index --chmod=+x`.

### L7 — Redis and PostgreSQL Are Single Points of Failure
Both have no clustering, no replication, no backup strategy. Disk failure = data loss.

### L8 — No Observability Stack
No log aggregation, no metrics (Prometheus), no alerting, no distributed tracing. Failures will go undetected until users report them.

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 5     |
| Medium   | 14    |
| Low      | 8     |

**Top priority fixes in order:**
1. Add `const path = require('path')` to `result/server.js` — service is currently broken
2. Remove hardcoded DB credentials, inject via env vars
3. Replace `emptyDir` with `PersistentVolumeClaim` for Postgres in K8s
4. Remove `|| true` from all Jenkins pipeline steps
5. Remove Docker socket mount from Trivy container
6. Set `debug=False` in `vote/app.py` and switch to gunicorn
