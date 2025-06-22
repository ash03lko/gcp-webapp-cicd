terraform {
  required_version = ">= 1.3.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.50.0"
    }
  }

  backend "gcs" {
    bucket = "graphite-store-tf-state"  # <-- Use your dedicated bucket name
    prefix = "terraform/state"
  }
}
