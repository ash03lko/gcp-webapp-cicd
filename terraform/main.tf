provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

# VPC
resource "google_compute_network" "vpc" {
  name = "web-vpc"
}

# Public subnet
resource "google_compute_subnetwork" "public" {
  name          = "public-subnet"
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
}

# Private subnet
resource "google_compute_subnetwork" "private" {
  name                    = "private-subnet"
  network                 = google_compute_network.vpc.id
  ip_cidr_range           = "10.0.2.0/24"
  region                  = var.region
  private_ip_google_access = true
}

# Static external IP
resource "google_compute_address" "web_static_ip" {
  name   = "web-static-ip"
  region = var.region
}

# Firewall for HTTP/HTTPS
resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"
}

# Compute Engine instance
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public.id
    access_config {
      nat_ip = google_compute_address.web_static_ip.address
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx google-fluentd
    systemctl enable nginx
    systemctl start nginx
    systemctl enable google-fluentd
    systemctl start google-fluentd
  EOT
}

# Email Notification Channel
resource "google_monitoring_notification_channel" "email_channel" {
  display_name = "Email Notifications"
  type         = "email"
  labels = {
    email_address = var.email_alert
  }
}

# CPU alert
resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name          = "High CPU Alert"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email_channel.id]

  conditions {
    display_name = "VM CPU > 80%"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.label.instance_id=\"${google_compute_instance.web_server.id}\""
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

# Output static IP
output "static_ip" {
  value = google_compute_address.web_static_ip.address
}
