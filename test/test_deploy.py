#!/bin/bash
set -e

IP="$1"
if [[ -z "$IP" ]]; then
  echo "Usage: $0 <web_server_external_ip>"
  exit 1
fi

echo "Testing app at http://$IP"
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" http://$IP)

if [[ "$HTTP_STATUS" == "200" ]]; then
  echo "✅ App is healthy, returned 200 OK"
else
  echo "❌ App health check failed, got HTTP $HTTP_STATUS"
  exit 1
fi
