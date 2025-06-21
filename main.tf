provider "google" {
  project = "graphite-store-463414-p2"
  region  = "us-central1"
}

# Reference existing VPC
data "google_compute_network" "vpc_network" {
  name = "my-vpc"
}

# Public subnet
resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "11.0.1.0/24"
  region        = "us-central1"
  network       = data.google_compute_network.vpc_network.id
}

# Private subnet (not used in VM but present)
resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-central1"
  network       = data.google_compute_network.vpc_network.id
}

# Firewall rules
resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https"
  network = data.google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_ssh_from_iap" {
  name    = "allow-ssh-from-iap"
  network = data.google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-ssh-enabled"]
}

# VM
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  tags         = ["iap-ssh-enabled", "http-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.name
    access_config {}
  }

  service_account {
    email  = "740942188157-compute@developer.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release nginx

    mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \$(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    systemctl start docker
    systemctl enable docker
    systemctl start nginx
    systemctl enable nginx

    gcloud auth configure-docker us-central1-docker.pkg.dev --quiet
    docker pull us-central1-docker.pkg.dev/graphite-store-463414-p2/my-repo/my-app:latest
    docker run -d --name my-app -p 8080:80 us-central1-docker.pkg.dev/graphite-store-463414-p2/my-repo/my-app:latest

    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    cat > /etc/nginx/sites-available/myapp <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
    ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
  EOT
}

output "web_server_external_ip" {
  value = google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip
}

# Monitoring + alerting
resource "google_monitoring_notification_channel" "email_channel" {
  display_name = "Email Alert"
  type         = "email"
  labels = {
    email_address = "ashweryaverma@gmail.com"
  }
}

resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name          = "High CPU Usage Alert"
  combiner              = "OR"
  enabled               = true
  notification_channels = [google_monitoring_notification_channel.email_channel.id]

  conditions {
    display_name = "VM CPU > 80%"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\" AND resource.label.instance_id=\"${google_compute_instance.web_server.id}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "60s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
}
