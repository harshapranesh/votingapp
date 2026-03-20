#!/bin/bash

set -e

# Python static check (vote)
echo "Running flake8 for vote service..."
docker run --rm -v $(pwd)/vote:/app -w /app python:3.11-slim bash -c "pip install flake8 && flake8 ."

# Node.js static check (result)
echo "Running eslint for result service..."
docker run --rm -v $(pwd)/result:/app -w /app node:20 bash -c "npm install --no-save eslint && npx eslint ."

# .NET static check (worker)
echo "Running dotnet format for worker service..."
docker run --rm -v $(pwd)/worker:/src -w /src mcr.microsoft.com/dotnet/sdk:8.0 dotnet format --verify-no-changes --severity error

echo "All static checks completed."
