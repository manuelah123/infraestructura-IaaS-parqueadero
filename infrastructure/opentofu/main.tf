terraform {
  required_version = ">= 1.0"
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "~> 0.1"
    }
  }
}

provider "incus" {
  remote = "unix"
}

locals {
  project = "parking-system-iaas"
  environment = "development"
  network_name = "incusbr0"
  network_cidr = "10.245.23.0/24"
}
