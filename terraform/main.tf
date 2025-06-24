provider "google" {
  project = "graphite-store-463414-p2"
  region  = "us-central1"
  zone    = "us-central1-a"
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
  region        = "us-central1"
}

# Private subnet
resource "google_compute_subnetwork" "private" {
  name          = "private-subnet"
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-central1"
  private_ip_google_access = true
}

# Static external IP
resource "google_compute_address" "web_static_ip" {
  name   = "web-static-ip"
  region = "us-central1"
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

# VM
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

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

# Monitoring alert
resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name = "High CPU Alert"
  combiner     = "OR"
  notification_channels = [] # Add channels later if needed

  conditions {
    display_name = "VM CPU > 80%"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.label.instance_id=\"${google_compute_instance.web_server.id}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "60s"
      aggregations {
        alignment_period    = "60s"
        per_series_aligner  = "ALIGN_MEAN"
      }
    }
  }
}

output "static_ip" {
  value = google_compute_address.web_static_ip.address
}
