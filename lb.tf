resource "digitalocean_loadbalancer" "api" {
  count  = 0                           // disable, pretty expensive
  name   = "${local.cluster_name}-api"
  region = "${var.region}"

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"

    target_port     = 443
    target_protocol = "https"

    tls_passthrough = true
  }

  healthcheck {
    port     = 22
    protocol = "tcp"
  }

  droplet_ids = ["${digitalocean_droplet.master.*.id}"]
}
