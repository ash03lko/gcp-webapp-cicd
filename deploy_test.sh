#!/bin/bash
set -e

IP=$1

if [ -z "$IP" ]; then
  echo "Usage: $0 <IP>"
  exit 1
fi

echo "Running tests against http://$IP"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$IP)

if [ "$STATUS" -eq 200 ]; then
  echo "✅ App is healthy!"
else
  echo "❌ App test failed. Status code: $STATUS"
  exit 1
fi
