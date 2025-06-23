#!/bin/bash

set -e

# Fetch external IP from Terraform output
EXTERNAL_IP=$(terraform output -raw web_server_external_ip)

echo "🌐 Testing server at http://${EXTERNAL_IP} ..."

# Give the server a few seconds in case it's still starting up
sleep 10

# Test HTTP response
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}" http://${EXTERNAL_IP})

if [ "$HTTP_STATUS" -eq 200 ]; then
  echo "✅ Server responded with HTTP 200 OK"
else
  echo "❌ Server did not respond with HTTP 200 OK. Got: $HTTP_STATUS"
  exit 1
fi

# Optionally check page content
PAGE_CONTENT=$(curl -s http://${EXTERNAL_IP})

if echo "$PAGE_CONTENT" | grep -q "Welcome to Nginx"; then
  echo "✅ NGINX welcome page detected"
else
  echo "❌ NGINX welcome page not detected"
  exit 1
fi

echo "🎉 All tests passed!"
