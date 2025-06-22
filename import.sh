#!/bin/bash
set -e

echo "🔑 Importing resources into Terraform state..."

terraform state list | grep google_compute_network.vpc_network || \
  terraform import google_compute_network.vpc_network my-vpc

terraform state list | grep google_compute_subnetwork.public_subnet || \
  terraform import google_compute_subnetwork.public_subnet us-central1/public-subnet

terraform state list | grep google_compute_subnetwork.private_subnet || \
  terraform import google_compute_subnetwork.private_subnet us-central1/private-subnet

terraform state list | grep google_compute_firewall.allow_http_https || \
  terraform import google_compute_firewall.allow_http_https projects/graphite-store-463414-p2/global/firewalls/allow-http-https

terraform state list | grep google_compute_firewall.allow_ssh_from_iap || \
  terraform import google_compute_firewall.allow_ssh_from_iap projects/graphite-store-463414-p2/global/firewalls/allow-ssh-from-iap

terraform state list | grep google_compute_instance.web_server || \
  terraform import google_compute_instance.web_server projects/graphite-store-463414-p2/zones/us-central1-a/instances/web-server

echo "✅ Import completed."
