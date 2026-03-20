# Local Run Guide

## Requirements

- Docker 24+
- Docker Compose v2+

Check versions:

docker --version
docker compose version

---

## Start the application

Build and start containers:

docker compose up -d --build

Services:

Vote UI: http://localhost:8080  
Result UI: http://localhost:8081  

---

## Stop the application

docker compose down

---

## View logs

Show logs for all services:

docker compose logs -f --tail=100

Show logs for specific service:

docker compose logs vote
docker compose logs result
docker compose logs worker
docker compose logs db

---

## Clean reset (if something breaks)

docker compose down -v
