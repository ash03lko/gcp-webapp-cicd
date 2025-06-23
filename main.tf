provider "google" {
  project = "graphite-store-463414-p2"
  region  = "us-central1"
  zone    = "us-central1-a"
}

# VPC
resource "google_compute_network" "vpc_network" {
  name = "my-vpc"
}

# Public subnet
resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "11.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id
}

# Private subnet
resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id
}

# Allow HTTP/HTTPS
resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Allow SSH from IAP
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

# VM instance
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"
  zone         = "us-central1-a"
  tags         = ["http-server", "iap-ssh-enabled"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.public_subnet.id

    access_config {
      # ephemeral external IP
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release

    mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \$(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    systemctl enable docker
    systemctl start docker

    gcloud auth configure-docker us-central1-docker.pkg.dev --quiet

    docker pull us-central1-docker.pkg.dev/graphite-store-463414-p2/my-repo/my-app:latest
    docker run -d --name my-app -p 80:80 us-central1-docker.pkg.dev/graphite-store-463414-p2/my-repo/my-app:latest
  EOT

  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  labels = {
    goog-terraform-provisioned = "true"
  }
}

# Notification channel
resource "google_monitoring_notification_channel" "email_channel" {
  display_name = "Email Alert"
  type         = "email"
  labels = {
    email_address = "ashweryaverma@gmail.com"
  }
  enabled = true
}

# Alerting policy
resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name = "High CPU Usage Alert"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "VM CPU > 80%"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.label.instance_id=monitoring.regex.full_match(\"${google_compute_instance.web_server.instance_id}\")"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "60s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_channel.name]
}


