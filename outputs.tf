output "ipv4" {
  value = data.ovh_dedicated_server.relay.ip
}

output "ssh" {
  value = "ssh ${var.ssh_user}@${data.ovh_dedicated_server.relay.ip}"
}

output "fingerprint_hint" {
  value = "Fingerprint: ssh in and run `sudo cat /var/lib/tor/fingerprint`, then look it up on https://metrics.torproject.org/rs.html after ~3h."
}
