#!/bin/bash

COLOR=$1

if [ "$COLOR" = "blue" ]; then
  PORT=8081
else
  PORT=8082
fi

echo "Testing $COLOR on port $PORT..."

STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT)

if [ "$STATUS" = "200" ]; then
  echo "OK"
  exit 0
else
  echo "FAILED"
  exit 1
fi