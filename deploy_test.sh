#!/bin/bash

# Check if IP argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <IP>"
  exit 1
fi

IP="$1"
URL="http://$IP"

echo "Running deployment test on $URL ..."

# Attempt to fetch the homepage
if curl -f --max-time 10 "$URL"; then
  echo "✅ Deployment test passed: App is reachable at $URL"
else
  echo "❌ Deployment test failed: App is not reachable at $URL"
  exit 1
fi
