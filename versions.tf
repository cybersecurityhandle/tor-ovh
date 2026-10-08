terraform {
  required_version = ">= 1.5"

  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.22"
    }
  }
}

# Credentials come from the environment, never from tfvars:
#   OVH_APPLICATION_KEY, OVH_APPLICATION_SECRET, OVH_CONSUMER_KEY
# (or OVH_CLIENT_ID / OVH_CLIENT_SECRET for OAuth2 service accounts).
provider "ovh" {
  endpoint = var.ovh_endpoint
}
