# Static Code Checks Guide

This project enforces static code analysis for all services. Use the provided script to run checks locally or in CI/CD.

## How to Run All Static Checks

```bash
chmod +x run-static-checks.sh
./run-static-checks.sh
```

## Per-Service Details

### vote/ (Python)
- **Tool:** flake8
- **Config:** vote/.flake8
- **Run manually:**
  ```bash
  docker run --rm -v $(pwd)/vote:/app -w /app python:3.11-slim bash -c "pip install flake8 && flake8 ."
  ```

### result/ (Node.js)
- **Tool:** eslint
- **Config:** result/.eslintrc.json
- **Run manually:**
  ```bash
  docker run --rm -v $(pwd)/result:/app -w /app node:20 bash -c "npm install --no-save eslint && npx eslint ."
  ```

### worker/ (C#/.NET)
- **Tool:** dotnet format
- **Config:** worker/.editorconfig, worker/.dotnet-format-config.json
- **Run manually:**
  ```bash
  docker run --rm -v $(pwd)/worker:/src -w /src mcr.microsoft.com/dotnet/sdk:8.0 dotnet format --verify-no-changes --severity error
  ```

## CI/CD Integration

Add the following step to your pipeline before build or deploy:

```bash
./run-static-checks.sh
```

If any check fails, the pipeline will stop with a non-zero exit code.

---

For more details, see each tool's documentation:
- [flake8](https://flake8.pycqa.org/)
- [eslint](https://eslint.org/)
- [dotnet format](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-format)
