data "ignition_config" "worker" {
  count = "${var.worker_count}"

  files = [
    "${data.ignition_file.ca_crt.id}",
    "${data.ignition_file.kubeconfig.id}",
    "${data.ignition_file.hostname_worker.*.id[count.index]}",
    "${data.ignition_file.resolv_conf.id}",
  ]

  systemd = [
    "${data.ignition_systemd_unit.hyperkube_download.id}",
    "${data.ignition_systemd_unit.kubelet_worker.id}",
    "${data.ignition_systemd_unit.proxy.id}",
    "${data.ignition_systemd_unit.vultr_metadata.id}",
  ]

  networkd = [
    "${data.ignition_networkd_unit.eth1.id}",
  ]

  users = [
    "${data.ignition_user.core.id}",
  ]
}

data "template_file" "kubelet_worker" {
  template = "${file("${path.module}/systemd/kubelet.service")}"

  vars {
    flags = "--node-labels=node-role.kubernetes.io/worker"
  }
}

data "ignition_systemd_unit" "kubelet_worker" {
  content = "${data.template_file.kubelet_worker.rendered}"
  enabled = true
  name    = "kubelet.service"
}

data "ignition_file" "hostname_worker" {
  count      = "${var.worker_count}"
  path       = "/etc/hostname"
  mode       = 0644
  uid        = 0
  filesystem = "root"

  content {
    content = "worker-${local.cluster_name}-${count.index}"
  }
}
