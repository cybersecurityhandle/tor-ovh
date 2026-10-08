variable "ovh_endpoint" {
  description = "OVH API endpoint: ovh-ca (OVHcloud Canada/US accounts), ovh-eu, ovh-us."
  type        = string
  default     = "ovh-ca"
}

variable "service_name" {
  description = "Dedicated server service name, e.g. ns1234567.ip-1-2-3.net (OVH manager > Bare Metal Cloud)."
  type        = string
}

variable "os_template" {
  description = "OVH installation template."
  type        = string
  default     = "debian12_64"
}

variable "hostname" {
  type    = string
  default = "tor-relay"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

variable "ssh_private_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519"
}

variable "ssh_user" {
  description = "Default user created by OVH's Debian templates."
  type        = string
  default     = "debian"
}

variable "reverse_dns" {
  description = "Optional PTR for the server IPv4 (must already resolve forward to the IP). Empty to skip."
  type        = string
  default     = ""
}

# --- Tor ---------------------------------------------------------------

variable "nickname" {
  description = "Relay nickname: 1-19 alphanumeric chars."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9]{1,19}$", var.nickname))
    error_message = "Nickname must be 1-19 alphanumeric characters."
  }
}

variable "contact_info" {
  description = "Operator contact published in the consensus (email, ideally ContactInfo-spec formatted)."
  type        = string
}

variable "or_port" {
  description = "Tor ORPort. 443 is reachable from most restrictive networks."
  type        = number
  default     = 443
}

variable "bandwidth_rate" {
  description = "RelayBandwidthRate, e.g. \"20 MBytes\"."
  type        = string
  default     = "20 MBytes"
}

variable "bandwidth_burst" {
  type    = string
  default = "40 MBytes"
}

variable "accounting_max" {
  description = "Monthly traffic cap per direction, e.g. \"10 TBytes\". Empty for unlimited (OVH dedicated is usually unmetered)."
  type        = string
  default     = ""
}
