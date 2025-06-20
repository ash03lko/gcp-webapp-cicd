#!/bin/bash
set -ex
trap 'echo "❌ Deployment failed!"' ERR

VM_NAME="web-server"
ZONE="us-central1-a"
IMAGE_URI="us-central1-docker.pkg.dev/graphite-store-463414-p2/my-repo/my-app:latest"

# Fetch OS Login username dynamically
OSLOGIN_USER=$(gcloud compute os-login describe-profile --format='value(posixAccounts[0].username)')

echo "🚀 Pulling and running Docker image on VM..."
gcloud compute ssh ${OSLOGIN_USER}@${VM_NAME} --zone ${ZONE} --command "
  sudo docker pull ${IMAGE_URI}
  sudo docker stop my-app || true
  sudo docker rm my-app || true
  sudo docker run -d --name my-app -p 80:80 ${IMAGE_URI}
"

echo "✅ App container deployed successfully!"
