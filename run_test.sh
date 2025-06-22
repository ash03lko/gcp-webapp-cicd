#!/bin/bash
set -e

echo "Fetching external IP..."
IP=$(terraform output -raw web_server_external_ip)
echo "External IP: $IP"

APP_URL="http://$IP"
APP_URL=$APP_URL python3 -m unittest test/test_deploy.py
