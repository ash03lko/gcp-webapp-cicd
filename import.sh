#!/bin/bash
set -euo pipefail  # Also fail on unset vars and pipe errors

echo "🔑 Importing resources into Terraform state..."

if ! terraform state list | grep -q google_compute_network.vpc_network; then
  terraform import google_compute_network.vpc_network my-vpc
fi

if ! terraform state list | grep -q google_compute_subnetwork.public_subnet; then
  terraform import google_compute_subnetwork.public_subnet us-central1/public-subnet
fi

if ! terraform state list | grep -q google_compute_subnetwork.private_subnet; then
  terraform import google_compute_subnetwork.private_subnet us-central1/private-subnet
fi

if ! terraform state list | grep -q google_compute_firewall.allow_http_https; then
  terraform import google_compute_firewall.allow_http_https projects/graphite-store-463414-p2/global/firewalls/allow-http-https
fi

if ! terraform state list | grep -q google_compute_firewall.allow_ssh_from_iap; then
  terraform import google_compute_firewall.allow_ssh_from_iap projects/graphite-store-463414-p2/global/firewalls/allow-ssh-from-iap
fi

if ! terraform state list | grep -q google_compute_instance.web_server; then
  terraform import google_compute_instance.web_server projects/graphite-store-463414-p2/zones/us-central1-a/instances/web-server
fi

echo "✅ Import completed."
