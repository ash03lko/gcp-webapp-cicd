#!/bin/bash
set -e

VM_NAME="web-server"
ZONE="us-central1-a"
VM_USER="ashweryaverma"

echo "📦 Copying app files to VM..."
gcloud compute scp --recurse app/ ${VM_USER}@${VM_NAME}:/home/${VM_USER}/app --zone ${ZONE}

echo "🚀 Running app on VM..."
gcloud compute ssh ${VM_USER}@${VM_NAME} --zone ${ZONE} --command "
  sudo pkill -f 'python3 /home/${VM_USER}/app/main.py' || true
  nohup python3 /home/${VM_USER}/app/main.py > app.log 2>&1 &
"

echo "✅ App deployed successfully!"
