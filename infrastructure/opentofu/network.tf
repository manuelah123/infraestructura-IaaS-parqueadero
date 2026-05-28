resource "incus_network" "parking" {
  name = local.network_name
  config = {
    "ipv4.address"   = "10.245.23.1/24"
    "ipv4.nat"       = "true"
    "ipv6.address"   = "none"
    "dhcp4"          = "false"
    "dns.mode"       = "managed"
    "dns.domain"     = "parking.local"
  }
}
