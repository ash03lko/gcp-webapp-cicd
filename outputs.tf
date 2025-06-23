output "web_server_external_ip" {
  description = "The external IP of the public web server"
  value       = google_compute_instance.public_web_server.network_interface[0].access_config[0].nat_ip
}

output "web_server_internal_ip" {
  description = "The internal IP of the public web server"
  value       = google_compute_instance.public_web_server.network_interface[0].network_ip
}
