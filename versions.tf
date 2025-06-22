terraform {
  required_version = ">= 1.3.0"

  backend "gcs" {
    bucket = "graphite-store-463414-p2_cloudbuild"
    prefix = "terraform/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.50.0"
    }
  }
}
