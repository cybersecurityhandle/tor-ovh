# tor-ovh

Terraform that turns an OVH dedicated server into a **non-exit Tor relay** (a middle relay, which can later become a guard).

It does the following:

- Reinstalls the server with Debian 12 and your SSH key, through the OVH API.
- Installs Tor from the official `deb.torproject.org` repository.
- Writes `/etc/tor/torrc` from [`templates/torrc.tftpl`](templates/torrc.tftpl) with exiting disabled.
- Sets up an nftables firewall that drops all inbound traffic except the ORPort and SSH, with SSH rate-limited.
- Turns on unattended security upgrades for Debian and the Tor repository.
- Optionally sets reverse DNS on the server's IPv4 address.

> [!WARNING]
> `terraform apply` **wipes the server** on the first run, and again whenever `os_template`, `hostname` or the SSH key changes. Changes to the Tor config or the firewall are re-applied over SSH without a reinstall.

## Requirements

- Terraform 1.5 or later.
- An OVH dedicated server you're willing to reinstall.
- OVH API credentials. Create them at <https://ca.api.ovh.com/createToken/> (use `eu.api.ovh.com` or `api.us.ovhcloud.com` for those regions) with these rights:
  - `GET`, `POST` and `PUT` on `/dedicated/server/*`
  - `GET`, `POST` and `PUT` on `/ip/*` (needed only for reverse DNS)
  - `GET` on `/me`

## Usage

```bash
export OVH_APPLICATION_KEY=...
export OVH_APPLICATION_SECRET=...
export OVH_CONSUMER_KEY=...

cp terraform.tfvars.example terraform.tfvars   # set service_name, nickname, contact_info
terraform init
terraform plan
terraform apply
```

After the apply:

```bash
ssh debian@<ipv4>
sudo journalctl -u tor@default -f          # look for "Self-testing indicates your ORPort is reachable"
sudo cat /var/lib/tor/fingerprint
```

The relay shows up on [Relay Search](https://metrics.torproject.org/rs.html) within a few hours. It takes several weeks for its traffic to ramp up. See [the lifecycle of a new relay](https://blog.torproject.org/lifecycle-of-a-new-relay/).

## Variables

| Name | Default | Notes |
|---|---|---|
| `service_name` | (required) | The server's name in the OVH manager, e.g. `ns1234567.ip-1-2-3.net` |
| `nickname` | (required) | 1–19 alphanumeric characters |
| `contact_info` | (required) | Published in the consensus. The [ContactInfo spec](https://nusenu.github.io/ContactInfo-Information-Sharing-Specification/) format is recommended |
| `ovh_endpoint` | `ovh-ca` | `ovh-eu` and `ovh-us` also work |
| `os_template` | `debian12_64` | |
| `or_port` | `443` | |
| `bandwidth_rate` / `bandwidth_burst` | `20 MBytes` / `40 MBytes` | |
| `accounting_max` | (none) | Monthly cap per direction, e.g. `10 TBytes`. Leave unset for unmetered servers |
| `reverse_dns` | (none) | The name must already resolve to the server's IP |
| `ssh_public_key_path` / `ssh_private_key_path` | `~/.ssh/id_ed25519(.pub)` | |

## Notes

- **Exit relays:** this setup deliberately runs a non-exit relay. Exit traffic generates abuse complaints sent to your hosting provider. Check your OVH product's terms, and get written approval from OVH, before changing the exit policy.
- **State:** Terraform state is kept locally and ignored by git. It contains the server ID and IP but no credentials. Keep it backed up if you rely on it.
- **Running several relays:** if you run more than one relay, declare them as a family. See [`FamilyId`](https://community.torproject.org/relay/setup/post-install/family-ids/).
