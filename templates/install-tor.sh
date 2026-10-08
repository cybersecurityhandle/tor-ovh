#!/usr/bin/env bash
# Installs Tor from deb.torproject.org, applies torrc + nftables. Idempotent.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

. /etc/os-release
arch=$(dpkg --print-architecture)

apt-get update -q
apt-get install -yq apt-transport-https ca-certificates curl gpg nftables unattended-upgrades

install -d -m 0755 /usr/share/keyrings
curl -fsSL https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc \
  | gpg --dearmor --yes -o /usr/share/keyrings/deb.torproject.org-keyring.gpg

cat > /etc/apt/sources.list.d/tor.list <<LIST
deb     [arch=${arch} signed-by=/usr/share/keyrings/deb.torproject.org-keyring.gpg] https://deb.torproject.org/torproject.org ${VERSION_CODENAME} main
deb-src [arch=${arch} signed-by=/usr/share/keyrings/deb.torproject.org-keyring.gpg] https://deb.torproject.org/torproject.org ${VERSION_CODENAME} main
LIST

apt-get update -q
apt-get install -yq tor deb.torproject.org-keyring

# Auto-apply security updates, including the Tor repo.
cat > /etc/apt/apt.conf.d/51unattended-upgrades-tor <<'CONF'
Unattended-Upgrade::Origins-Pattern {
  "origin=Debian,codename=${distro_codename},label=Debian-Security";
  "origin=TorProject";
};
Unattended-Upgrade::Automatic-Reboot "false";
CONF
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'CONF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
CONF

install -m 0644 /tmp/nftables.conf /etc/nftables.conf
nft -c -f /etc/nftables.conf
systemctl enable --now nftables
systemctl reload nftables || systemctl restart nftables

install -m 0644 /tmp/torrc /etc/tor/torrc
sudo -u debian-tor tor --verify-config -f /etc/tor/torrc
systemctl enable tor
systemctl restart tor

rm -f /tmp/torrc /tmp/nftables.conf /tmp/install-tor.sh
echo "tor $(tor --version | head -1) running"
