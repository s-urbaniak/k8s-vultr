data "ignition_config" "ipxe" {
  count = "${var.master_count}"

  systemd = [
    "${data.ignition_systemd_unit.install.id}",
    "${data.ignition_systemd_unit.install_path.id}",
  ]

  users = [
    "${data.ignition_user.install.id}",
  ]
}

data "ignition_config" "ipxe_worker" {
  count = "${var.worker_count}"

  systemd = [
    "${data.ignition_systemd_unit.install.id}",
    "${data.ignition_systemd_unit.install_path.id}",
  ]

  users = [
    "${data.ignition_user.install.id}",
  ]

  files = [
    "${data.ignition_file.ignition_worker.*.id[count.index]}",
  ]
}

data "ignition_file" "ignition_worker" {
  count = "${var.worker_count}"

  path       = "/home/install/ignition"
  mode       = 0644
  uid        = 0
  filesystem = "root"

  content {
    content = "${data.ignition_config.worker.*.rendered[count.index]}"
  }
}

data "ignition_systemd_unit" "install" {
  content = "${file("${path.module}/systemd/install.service")}"
  enabled = false
  name    = "install.service"
}

data "ignition_systemd_unit" "install_path" {
  content = "${file("${path.module}/systemd/install.path")}"
  enabled = true
  name    = "install.path"
}

data "ignition_user" "install" {
  name                = "install"
  ssh_authorized_keys = "${var.ssh_authorized_key_list}"

  groups = [
    "sudo",
    "docker",
  ]
}
