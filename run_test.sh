#!/bin/bash
set -e

echo "Fetching external IP..."
IP=$(terraform output -raw web_server_external_ip)

if [ -z "$IP" ]; then
  echo "Failed to get external IP"
  exit 1
fi

echo "External IP is: $IP"

# Run your test script
./deploy_test.sh "$IP"
