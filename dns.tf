data "template_file" "master_fqdn" {
  count    = "${var.master_count}"
  template = "master-${local.cluster_name}-${count.index}.${var.cluster_base_domain}"
}

resource "vultr_dns_record" "master" {
  count = "${var.master_count}"

  domain = "${var.cluster_base_domain}"
  name   = "master-${local.cluster_name}-${count.index}"
  ttl    = 600
  type   = "A"
  data   = "${vultr_instance.master.*.ipv4_private_address[count.index]}"
}

resource "vultr_dns_record" "worker" {
  count = "${var.worker_count}"

  domain = "${var.cluster_base_domain}"
  name   = "worker-${local.cluster_name}-${count.index}"
  ttl    = 600
  type   = "A"
  data   = "${vultr_instance.worker.*.ipv4_private_address[count.index]}"
}

resource "vultr_dns_record" "api" {
  count = "${var.master_count}"

  domain = "${var.cluster_base_domain}"
  name   = "api-${local.cluster_name}"
  ttl    = 600
  type   = "A"
  data   = "${vultr_instance.master.*.ipv4_address[count.index]}"
}
