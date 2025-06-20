VM_NAME="web-server"
ZONE="us-central1-a"
OSLOGIN_USER="ashweryaverma_gmail_com"

EXTERNAL_IP=$(gcloud compute instances describe ${VM_NAME} --zone ${ZONE} --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "📦 Copying app files to VM..."
gcloud compute scp --recurse app/ ${OSLOGIN_USER}@${EXTERNAL_IP}:/home/${OSLOGIN_USER}/app --zone ${ZONE}

echo "🚀 Running app on VM..."
gcloud compute ssh ${OSLOGIN_USER}@${EXTERNAL_IP} --zone ${ZONE} --command "
  sudo pkill -f 'python3 /home/${OSLOGIN_USER}/app/main.py' || true
  nohup python3 /home/${OSLOGIN_USER}/app/main.py > app.log 2>&1 &
"

echo "✅ App deployed successfully!"
