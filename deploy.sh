#!/bin/bash
set -ex
trap 'echo "❌ Deployment failed!"' ERR

VM_NAME="web-server"
ZONE="us-central1-a"

# Use your valid OS Login user
OSLOGIN_USER="ashweryaverma_gmail_com"

echo "📦 Copying app files to VM..."
gcloud compute scp --tunnel-through-iap --recurse app/ ${OSLOGIN_USER}@${VM_NAME}:/home/${OSLOGIN_USER}/app --zone ${ZONE}

echo "🚀 Running app on VM..."
gcloud compute ssh --tunnel-through-iap ${OSLOGIN_USER}@${VM_NAME} --zone ${ZONE} --command "
  sudo pkill -f 'python3 /home/${OSLOGIN_USER}/app/main.py' || true
  nohup python3 /home/${OSLOGIN_USER}/app/main.py > app.log 2>&1 &
"

echo "✅ App deployed successfully!"
