data "ovh_dedicated_server" "relay" {
  service_name = var.service_name
}

# WIPES THE SERVER. Every argument here is ForceNew, so changing any of them
# triggers a fresh OS install. Tor config lives in terraform_data.tor below so
# torrc changes never reinstall.
resource "ovh_dedicated_server_reinstall_task" "os" {
  service_name = data.ovh_dedicated_server.relay.service_name
  os           = var.os_template

  customizations {
    hostname = var.hostname
    ssh_key  = trimspace(file(pathexpand(var.ssh_public_key_path)))
  }
}

resource "ovh_ip_reverse" "relay" {
  count = var.reverse_dns == "" ? 0 : 1

  ip         = "${data.ovh_dedicated_server.relay.ip}/32"
  ip_reverse = data.ovh_dedicated_server.relay.ip
  reverse    = var.reverse_dns
}

locals {
  torrc = templatefile("${path.module}/templates/torrc.tftpl", {
    nickname        = var.nickname
    contact_info    = var.contact_info
    or_port         = var.or_port
    bandwidth_rate  = var.bandwidth_rate
    bandwidth_burst = var.bandwidth_burst
    accounting_max  = var.accounting_max
  })

  nftables = templatefile("${path.module}/templates/nftables.conf.tftpl", {
    or_port = var.or_port
  })
}

# Re-runs on reinstall or when torrc / firewall / install script change.
resource "terraform_data" "tor" {
  triggers_replace = [
    ovh_dedicated_server_reinstall_task.os.id,
    sha256(local.torrc),
    sha256(local.nftables),
    filesha256("${path.module}/templates/install-tor.sh"),
  ]

  connection {
    type        = "ssh"
    host        = data.ovh_dedicated_server.relay.ip
    user        = var.ssh_user
    private_key = file(pathexpand(var.ssh_private_key_path))
    timeout     = "15m"
  }

  provisioner "file" {
    content     = local.torrc
    destination = "/tmp/torrc"
  }

  provisioner "file" {
    content     = local.nftables
    destination = "/tmp/nftables.conf"
  }

  provisioner "file" {
    source      = "${path.module}/templates/install-tor.sh"
    destination = "/tmp/install-tor.sh"
  }

  provisioner "remote-exec" {
    inline = ["sudo bash /tmp/install-tor.sh"]
  }
}
