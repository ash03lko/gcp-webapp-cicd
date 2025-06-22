provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  ip_cidr_range = var.private_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

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

resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["http-server", "iap-ssh-enabled"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.public_subnet.id
    access_config {}
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

    gcloud auth configure-docker ${var.region}-docker.pkg.dev --quiet

    docker pull ${var.region}-docker.pkg.dev/${var.project_id}/my-repo/my-app:latest
    docker run -d --name my-app -p 80:80 ${var.region}-docker.pkg.dev/${var.project_id}/my-repo/my-app:latest
  EOT

  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  labels = {
    goog-terraform-provisioned = "true"
  }
}

resource "google_monitoring_notification_channel" "email_channel" {
  display_name = "Email Alert"
  type         = "email"
  labels = {
    email_address = var.email_alert
  }
  enabled = true
}

resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name = "High CPU Usage Alert"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "VM CPU > 80%"
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND resource.label.instance_id=\"${google_compute_instance.web_server.id}\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "60s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_channel.id]
  project               = var.project_id
}

output "web_server_external_ip" {
  description = "External IP of the web server"
  value       = google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip
}
