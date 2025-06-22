#!/bin/bash

set -e

IP="$1"
APP_URL="http://${IP}"

echo "🟢 Starting deploy test for $APP_URL"

# Retry logic
MAX_RETRIES=5
SLEEP_SECONDS=5

for i in $(seq 1 $MAX_RETRIES); do
  echo "Attempt $i: Checking app health at $APP_URL"
  STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL")
  if [ "$STATUS_CODE" -eq 200 ]; then
    echo "✅ App is healthy! Status code: $STATUS_CODE"
    exit 0
  else
    echo "⚠ App not ready (HTTP $STATUS_CODE). Retrying in $SLEEP_SECONDS seconds..."
    sleep $SLEEP_SECONDS
  fi
done

echo "❌ App did not become healthy after $MAX_RETRIES attempts"
exit 1
