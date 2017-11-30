resource "digitalocean_firewall" "rules" {
  name = "${local.cluster_name}-rules"

  droplet_ids = [
    "${digitalocean_droplet.master.*.id}",
    "${digitalocean_droplet.worker.*.id}",
  ]

  inbound_rule = [
    {
      protocol         = "icmp"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "80"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "443"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol   = "udp"
      port_range = "4789" // vxlan port

      source_droplet_ids = [
        "${digitalocean_droplet.master.*.id}",
        "${digitalocean_droplet.worker.*.id}",
      ]
    },
    {
      protocol   = "tcp"
      port_range = "2379" // etcd client port

      source_droplet_ids = [
        "${digitalocean_droplet.master.*.id}",
        "${digitalocean_droplet.worker.*.id}",
      ]
    },
    {
      protocol   = "tcp"
      port_range = "2380" // etcd peer port, only master droplets need this

      source_droplet_ids = [
        "${digitalocean_droplet.master.*.id}",
      ]
    },
    {
      protocol   = "tcp"
      port_range = "10250" // api server metrics port

      source_droplet_ids = [
        "${digitalocean_droplet.master.*.id}",
        "${digitalocean_droplet.worker.*.id}",
      ]
    },
    {
      protocol   = "tcp"
      port_range = "10251" // scheduler metrics port

      source_droplet_ids = [
        "${digitalocean_droplet.master.*.id}",
        "${digitalocean_droplet.worker.*.id}",
      ]
    },
    {
      protocol   = "tcp"
      port_range = "10252" // controller-manager metrics port

      source_droplet_ids = [
        "${digitalocean_droplet.master.*.id}",
        "${digitalocean_droplet.worker.*.id}",
      ]
    },
    {
      protocol   = "tcp"
      port_range = "10255" // kubelet metrics port

      source_droplet_ids = [
        "${digitalocean_droplet.master.*.id}",
        "${digitalocean_droplet.worker.*.id}",
      ]
    },
    {
      protocol   = "tcp"
      port_range = "4194" // cadvisor metrics port

      source_droplet_ids = [
        "${digitalocean_droplet.master.*.id}",
        "${digitalocean_droplet.worker.*.id}",
      ]
    },
    {
      protocol   = "tcp"
      port_range = "9100" // node exporter metrics port

      source_droplet_ids = [
        "${digitalocean_droplet.master.*.id}",
        "${digitalocean_droplet.worker.*.id}",
      ]
    },
  ]

  outbound_rule = [
    {
      protocol              = "tcp"
      port_range            = "all"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol              = "udp"
      port_range            = "all"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
  ]
}
