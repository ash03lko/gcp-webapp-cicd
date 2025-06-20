#!/bin/bash
set -ex
trap 'echo "❌ Deployment failed!"' ERR

VM_NAME="web-server"
ZONE="us-central1-a"

# Fetch OS Login username dynamically
OSLOGIN_USER=$(gcloud compute os-login describe-profile --format='value(posixAccounts[0].username)')

echo "📦 Copying app files to VM..."
gcloud compute scp --recurse app/ ${OSLOGIN_USER}@${VM_NAME}:/home/${OSLOGIN_USER}/app --zone ${ZONE}

echo "🚀 Running app on VM..."
gcloud compute ssh ${OSLOGIN_USER}@${VM_NAME} --zone ${ZONE} --command "
  sudo pkill -f 'python3 /home/${OSLOGIN_USER}/app/main.py' || true
  nohup python3 /home/${OSLOGIN_USER}/app/main.py > /home/${OSLOGIN_USER}/app/app.log 2>&1 &
"

echo "✅ App deployed successfully!"
