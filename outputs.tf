output "web_server_external_ip" {
  description = "Public IP of the web server"
  value       = google_compute_instance.public_web_server.network_interface[0].access_config[0].nat_ip
}
