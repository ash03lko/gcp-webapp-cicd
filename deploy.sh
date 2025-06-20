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
  # Ensure Docker is authenticated for root
  gcloud auth configure-docker us-central1-docker.pkg.dev --quiet
  sudo mkdir -p /root/.docker
  sudo cp ~/.docker/config.json /root/.docker/config.json

  # Pull and run the container on port 8080 to avoid conflict with Nginx
  sudo docker pull ${IMAGE_URI}
  sudo docker stop my-app || true
  sudo docker rm my-app || true
  sudo docker run -d --name my-app -p 8080:80 ${IMAGE_URI}

  # Configure Nginx reverse proxy (one-time setup)
  if [ ! -f /etc/nginx/sites-available/myapp ]; then
    sudo bash -c 'cat > /etc/nginx/sites-available/myapp <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF'
    sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl reload nginx
  fi
"

echo "✅ App container deployed successfully with Nginx reverse proxy!"
