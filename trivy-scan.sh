#!/bin/bash

# Trivy Security Scanning Script
# Scans Docker images and filesystem for vulnerabilities

set -e

echo "==================================="
echo "Starting Trivy Security Scans"
echo "==================================="

# Scan vote image
echo ""
echo "[1/4] Scanning vote image..."
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image --severity HIGH,CRITICAL \
  voting-app_vote:latest || true

# Scan result image
echo ""
echo "[2/4] Scanning result image..."
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image --severity HIGH,CRITICAL \
  voting-app_result:latest || true

# Scan worker image
echo ""
echo "[3/4] Scanning worker image..."
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image --severity HIGH,CRITICAL \
  voting-app_worker:latest || true

# Scan filesystem
echo ""
echo "[4/4] Scanning filesystem for vulnerabilities..."
docker run --rm -v $(pwd):/root \
  aquasec/trivy fs --severity HIGH,CRITICAL \
  /root || true

echo ""
echo "==================================="
echo "Trivy Scans Completed"
echo "==================================="
