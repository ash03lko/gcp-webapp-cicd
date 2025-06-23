variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "graphite-store-463414-p2"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "email_alert" {
  description = "Email for CPU alert notifications"
  type        = string
  default     = "ashweryaverma@gmail.com"
}
