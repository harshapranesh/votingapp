# Trivy Security Scanning Guide

Trivy is a comprehensive vulnerability scanner for Docker images and filesystems. This guide explains how to use Trivy with the voting app.

## Quick Start

### Option 1: Scan Images (Recommended for CI/CD)

```bash
# Scan a specific image
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image voting-app_vote:latest

# Scan with severity filter
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image --severity HIGH,CRITICAL voting-app_vote:latest
```

### Option 2: Scan Filesystem

```bash
# Scan current directory
docker run --rm -v ${PWD}:/root \
  aquasec/trivy fs /root

# Scan with severity filter
docker run --rm -v ${PWD}:/root \
  aquasec/trivy fs --severity HIGH,CRITICAL /root
```


### Option 3: Using Compose Override (with Pipeline Policy)

```bash
# Run entire stack with Trivy scanner
docker-compose -f docker-compose.yml -f docker-compose.trivy.yml up --profile scan
```

**Policy:** The pipeline will automatically fail if any High or Critical vulnerabilities are found, thanks to the `--exit-code 1` flag in `docker-compose.trivy.yml`.

### Option 4: Run Batch Scan Script

```bash
chmod +x trivy-scan.sh
./trivy-scan.sh
```

## Severity Levels

- **CRITICAL**: Most urgent, requires immediate action
- **HIGH**: Important vulnerabilities, should be addressed
- **MEDIUM**: Moderate risk, consider fixing
- **LOW**: Minor issues, can usually wait

## Ignoring Vulnerabilities

Add CVE IDs to `.trivyignore` file to skip specific vulnerabilities:

```
# Example .trivyignore
CVE-2024-1234
CVE-2024-5678
```

## Output Formats

Generate reports in different formats:

```bash
# JSON output
docker run --rm -v ${PWD}:/root \
  aquasec/trivy fs --format json --output /root/trivy-report.json /root

# SARIF format (for GitHub integration)
docker run --rm -v ${PWD}:/root \
  aquasec/trivy fs --format sarif --output /root/trivy-report.sarif /root

# Table format (human-readable)
docker run --rm -v ${PWD}:/root \
  aquasec/trivy fs --format table /root
```

## Integration with CI/CD


### Enforcing Failure on High/Critical Vulnerabilities

The Trivy integration is configured to fail the pipeline if any High or Critical vulnerabilities are detected. This is achieved by adding `--exit-code 1` to all Trivy scan commands in `docker-compose.trivy.yml`:

```yaml
command:
  - -c
  - |
    trivy image --severity HIGH,CRITICAL --exit-code 1 voting-app_vote:latest
    trivy image --severity HIGH,CRITICAL --exit-code 1 voting-app_result:latest
    trivy image --severity HIGH,CRITICAL --exit-code 1 voting-app_worker:latest
    trivy fs --severity HIGH,CRITICAL --exit-code 1 /scans
```

If any High or Critical vulnerabilities are found, the Trivy container will exit with code 1, causing the pipeline to fail.

## Useful Links

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [GitHub Repository](https://github.com/aquasecurity/trivy)
- [Docker Hub Image](https://hub.docker.com/r/aquasec/trivy)
