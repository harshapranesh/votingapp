This document describes how to verify that the Example Voting App is running correctly and all services are healthy.

---

## 1. Start the Application

From the project root directory run:

```bash
docker compose up -d --build
```

Verify that containers are running:

```bash
docker compose ps
```

Expected result:
- All services should be in **Up** state
- Services with healthchecks should show **healthy**

---

## 2. Verify Application URLs

### Vote Service

Access in browser:

http://localhost:8080

Or check using curl:

```bash
curl -I http://localhost:8080
```

Expected response:

```
HTTP/1.1 200 OK
```

---

### Result Service

Access in browser:

http://localhost:8081

Or check using curl:

```bash
curl -I http://localhost:8081
```

Expected response:

```
HTTP/1.1 200 OK
```

---

## 3. Verify Container Health Status

Check overall container status:

```bash
docker compose ps
```

To inspect health of a specific container:

```bash
docker inspect <container_name> --format='{{.State.Health.Status}}'
```

Expected status:

```
healthy
```

---

## 4. Verify Logs

Check logs for all services:

```bash
docker compose logs -f
```

Check logs for specific services:

```bash
docker compose logs -f vote
docker compose logs -f result
docker compose logs -f worker
```

Expected:
- No crash errors
- No restart loops
- Services responding normally

---

## 5. Verify Database and Redis

Check PostgreSQL container:

```bash
docker compose ps db
```

Check Redis container:

```bash
docker compose ps redis
```

Both services should be in:

- **Up**
- **Healthy** (if healthcheck is defined)

---

## 6. Stop the Application

To stop all services:

```bash
docker compose down
```

To stop and remove volumes:

```bash
docker compose down -v
```

---

# Baseline Health Criteria

The system is considered healthy when:

- All containers are running
- Healthchecks report **healthy**
- Vote UI loads successfully
- Result UI loads successfully
- No critical errors appear in logs