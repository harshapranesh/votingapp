#!/bin/sh

curl -sS -X POST --data "vote=b" http://vote > /dev/null
while ! timeout 1 bash -c "echo > /dev/tcp/vote/80"; do
    sleep 1
done


sleep 10

phantomjs render.js http://result > test-output.txt
if grep -q '1 vote' test-output.txt; then
  echo "------------" > test-report.txt
  echo "Tests passed" >> test-report.txt
  echo "------------" >> test-report.txt
  cat test-output.txt >> test-report.txt
  exit 0
else
  echo "------------" > test-report.txt
  echo "Tests failed" >> test-report.txt
  echo "------------" >> test-report.txt
  cat test-output.txt >> test-report.txt
  exit 1
fi
