variable "project_id" {
  default = "graphite-store-463414-p2"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
}

variable "email_alert" {
  default = "ashweryaverma@gmail.com"
}

resource "google_compute_network" "vpc_network" {
  name = "webapp-vpc"
}

resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_subnetwork" "private_subnet" {
  name                    = "private-subnet"
  ip_cidr_range           = "10.0.2.0/24"
  region                  = var.region
  network                 = google_compute_network.vpc_network.id
  private_ip_google_access = true
}

resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

resource "google_compute_firewall" "allow_ssh_webapp" {
  name    = "allow-ssh-webapp"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

resource "google_compute_instance" "web_instance" {
  name         = "web-server"
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["web-server", "http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.id
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo apt update
    sudo apt install -y nginx google-fluentd
    sudo systemctl enable nginx
    sudo systemctl start nginx
    sudo systemctl enable google-fluentd
    sudo systemctl start google-fluentd
  EOT

  metadata = {
    ssh-keys = "cloudbuild:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDWBQFTgAmsPatv3nBUHH8UiZacCA9t5qwg+aLZ4CBm+lt6FJ0OMquNS5i2ebIUH4JXC0Qpwxq41lEkQj04KRqzUDfa0vgel0tBKCmSsLqobKh6FvkmgPdjRox/F77sTs0Y6bfMGacBES8MhiwQnqXEdSaGxMgZKpnrf7QIhQTe2cQQtdmSH4Rwr6wAXcvP0Al9lxg+FwThCdocxH5vrPXr/r5Lj1i4eV7y8AZwz/RWfCA+Ems8m8C2nuHByIr8Fbucv7aDrvoyUrhiFn9hGpMP4XZh/88B1ieHeRebHNWeCuGd8JSDtLMp98+1/Zv6nZyyBaCVYxBerTybUX0fRLpF/ZiVtuA8kQFQGiKS74KoUlypAXw9f82JfR4TtO599kMdLysW0+jPelQJQcQB8C0dCFyeMu+O0k5n6nKxDThwF7i6RRKvMI5KfCNKAaUmBSeb+KNXFEun1mV54vp6rt1ZG0BKRvtEt0ybGUTybqKvHa9GhbO8aNj3MHndQCPlsMU= cloudbuild-key"
  }
}

resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Notification"
  type         = "email"
  labels = {
    email_address = var.email_alert
  }
}

resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name = "High CPU Alert"
  combiner     = "OR"

  conditions {
    display_name = "VM CPU > 80%"
    condition_threshold {
      filter = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.label.instance_id=\"${google_compute_instance.web_instance.instance_id}\""
      duration = "60s"
      comparison = "COMPARISON_GT"
      threshold_value = 0.8
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
  enabled = true
}
