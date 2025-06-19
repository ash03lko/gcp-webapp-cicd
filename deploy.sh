#!/bin/bash
set -e

VM_NAME="my-web-vm"
ZONE="us-central1-a"

echo "📦 Copying app files to VM..."
gcloud compute scp --recurse app/ $VM_NAME:/home/$USER/app --zone $ZONE

echo "🚀 Running app on VM..."
gcloud compute ssh $VM_NAME --zone $ZONE --command "
  sudo pkill -f 'python3 /home/$USER/app/main.py' || true
  nohup python3 /home/$USER/app/main.py > app.log 2>&1 &
"

echo "✅ App deployed successfully!"
