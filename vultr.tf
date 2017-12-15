data "vultr_region" "cluster" {
  filter {
    name = "name"

    values = [
      "Amsterdam",
    ]
  }
}

data "vultr_os" "custom" {
  filter {
    name   = "family"
    values = ["iso"]
  }
}

data "vultr_plan" "master" {
  filter {
    name   = "price_per_month"
    values = ["10.00"]
  }

  filter {
    name   = "ram"
    values = ["2048"]
  }
}

data "vultr_plan" "worker" {
  filter {
    name   = "price_per_month"
    values = ["10.00"]
  }

  filter {
    name   = "ram"
    values = ["2048"]
  }
}

resource "vultr_instance" "master" {
  count = "${var.master_count}"

  hostname           = "master-${local.cluster_name}-${count.index}"
  name               = "master-${local.cluster_name}-${count.index}"
  os_id              = "${data.vultr_os.custom.id}"
  plan_id            = "${data.vultr_plan.master.id}"
  private_networking = true
  region_id          = "${data.vultr_region.cluster.id}"
  startup_script_id  = "${vultr_startup_script.ipxe.id}"
  tag                = "container-linux"
  user_data          = "${data.ignition_config.ipxe.*.rendered[count.index]}"
}

resource "vultr_instance" "worker" {
  count = "${var.worker_count}"

  hostname           = "worker-${local.cluster_name}-${count.index}"
  name               = "worker-${local.cluster_name}-${count.index}"
  os_id              = "${data.vultr_os.custom.id}"
  plan_id            = "${data.vultr_plan.worker.id}"
  private_networking = true
  region_id          = "${data.vultr_region.cluster.id}"
  startup_script_id  = "${vultr_startup_script.ipxe.id}"
  tag                = "container-linux"
  user_data          = "${data.ignition_config.ipxe_worker.*.rendered[count.index]}"
}

resource "vultr_startup_script" "ipxe" {
  type    = "pxe"
  name    = "${local.cluster_name}"
  content = "${file("${path.module}/resources/ipxe")}"
}

resource "null_resource" "install" {
  count = "${var.master_count}"

  connection {
    host  = "${vultr_instance.master.*.ipv4_address[count.index]}"
    user  = "install"
    agent = true
  }

  provisioner "file" {
    content     = "${data.ignition_config.master.*.rendered[count.index]}"
    destination = "$HOME/ignition.transfer"
  }

  provisioner "remote-exec" {
    inline = [
      "mv $HOME/ignition.transfer $HOME/ignition",
    ]
  }
}
