data "template_file" "master_fqdn" {
  count    = "${var.master_count}"
  template = "master-${local.cluster_name}-${count.index}.${var.cluster_base_domain}"
}

resource "digitalocean_record" "master" {
  count  = "${var.master_count}"
  domain = "${var.cluster_base_domain}"
  name   = "master-${local.cluster_name}-${count.index}"
  ttl    = 600
  type   = "A"
  value  = "${digitalocean_droplet.master.*.ipv4_address_private[count.index]}"
}

resource "digitalocean_record" "worker" {
  count  = "${var.worker_count}"
  domain = "${var.cluster_base_domain}"
  name   = "worker-${local.cluster_name}-${count.index}"
  ttl    = 600
  type   = "A"
  value  = "${digitalocean_droplet.worker.*.ipv4_address_private[count.index]}"
}

resource "digitalocean_record" "api" {
  count  = "${var.master_count}"
  domain = "${var.cluster_base_domain}"
  name   = "api-${local.cluster_name}"
  ttl    = 600
  type   = "A"
  value  = "${digitalocean_droplet.master.*.ipv4_address[count.index]}"
}
