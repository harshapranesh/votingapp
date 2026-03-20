# Task 6 – Ports, Dependencies and Baseline Resource Requirements

## 1. Exposed Ports

The following ports are exposed to the host machine:

- Vote service: 8080 -> 80  
  Access: http://localhost:8080

- Result service: 8081 -> 80  
  Access: http://localhost:8081

- Result debug port (Node.js): 127.0.0.1:9229 -> 9229  
  Used for local debugging only.

Redis and PostgreSQL are not exposed to the host and are accessible only inside the Docker network.

---

## 2. Service Dependencies

Based on docker-compose.yml:

- vote depends on redis (service_healthy condition)
- result depends on db (service_healthy condition)
- worker depends on redis and db (both must be healthy)
- seed (profile: seed) depends on vote

---

## 3. Volumes and Data Persistence

- ./vote -> /usr/local/app (development bind mount)
- ./result -> /usr/local/app (development bind mount)
- db-data -> /var/lib/postgresql/data (persistent PostgreSQL data)

---

## 4. Docker Networks

- front-tier: vote, result, seed
- back-tier: vote, result, worker, redis, db

---

## 5. Baseline Resource Requirements

Minimum recommended for local development:

- CPU: 2 cores
- RAM: 4 GB
- Disk: Several GB for Docker images and volumes
- Docker Desktop with Compose v2 support

No explicit CPU or memory limits are defined in docker-compose.yml.