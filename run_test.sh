#!/bin/bash
set -e

IP=$1

if [ -z "$IP" ]; then
  echo "❌ Usage: $0 <external_ip>"
  exit 1
fi

echo "🔍 Running health check against http://$IP ..."

STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$IP")

if [ "$STATUS" -eq 200 ]; then
  echo "✅ App is healthy (HTTP $STATUS)"
else
  echo "❌ App health check failed (HTTP $STATUS)"
  exit 1
fi
