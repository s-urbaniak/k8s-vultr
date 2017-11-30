resource "digitalocean_droplet" "master" {
  count              = "${var.master_count}"
  image              = "${var.image_name}"
  name               = "master-${local.cluster_name}-${count.index}.${var.cluster_base_domain}"
  private_networking = true
  region             = "${var.region}"
  size               = "${var.master_size}"
  ssh_keys           = "${var.ssh_key_id_list}"
  user_data          = "${data.ignition_config.master.*.rendered[count.index]}"
}

resource "digitalocean_droplet" "worker" {
  count              = "${var.worker_count}"
  image              = "${var.image_name}"
  name               = "worker-${local.cluster_name}-${count.index}.${var.cluster_base_domain}"
  private_networking = true
  region             = "${var.region}"
  size               = "${var.worker_size}"
  ssh_keys           = "${var.ssh_key_id_list}"
  user_data          = "${data.ignition_config.worker.*.rendered[count.index]}"
}
