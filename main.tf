provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# 🕸 VPC
resource "google_compute_network" "vpc_network" {
  name = "my-vpc"
}

# 🌐 Public subnet
resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "11.0.1.0/24"
  network       = google_compute_network.vpc_network.id
  region        = var.region
}

# 🔒 Private subnet
resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.2.0/24"
  network       = google_compute_network.vpc_network.id
  region        = var.region
}

# 🚪 Allow HTTP/HTTPS
resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# 🚪 Allow SSH from IAP
resource "google_compute_firewall" "allow_ssh_from_iap" {
  name    = "allow-ssh-from-iap"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-ssh-enabled"]
}

# 🖥️ Compute Engine
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-micro"
  zone         = var.zone
  tags         = ["http-server", "iap-ssh-enabled"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.name

    access_config {
      # ephemeral public IP
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release nginx

    # Docker install
    mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    systemctl start docker
    systemctl enable docker
    systemctl start nginx
    systemctl enable nginx

    gcloud auth configure-docker ${var.region}-docker.pkg.dev --quiet
    docker pull ${var.image_url}
    docker run -d --name my-app -p 8080:80 ${var.image_url}

    cat > /etc/nginx/sites-available/myapp <<NGINX
    server {
      listen 80;
      server_name _;
      location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
      }
    }
    NGINX
    ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
  EOT
}

# 📈 Monitoring notification
resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Alert"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
  enabled = true
}

# 📈 Monitoring alert
resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name = "High CPU Usage Alert"
  combiner     = "OR"
  enabled      = true
  project      = var.project_id

  conditions {
    display_name = "VM CPU > 80%"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" resource.type=\"gce_instance\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "60s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}

# 🌐 OUTPUT
output "web_server_external_ip" {
  value = google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip
}
