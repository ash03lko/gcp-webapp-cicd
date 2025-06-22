#!/bin/bash
set -e

IP=$1

if [[ -z "$IP" ]]; then
  echo "Error: IP not provided!"
  exit 1
fi

echo "Testing app at http://$IP ..."
curl --fail --silent --show-error "http://$IP" | grep "Hello from GCP app!"
echo "✅ App test passed!"
