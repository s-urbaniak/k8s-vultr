data "ignition_config" "worker" {
  count = "${var.worker_count}"

  files = [
    "${data.ignition_file.ca_crt.id}",
    "${data.ignition_file.kubeconfig.id}",
  ]

  systemd = [
    "${data.ignition_systemd_unit.hyperkube_download.id}",
    "${data.ignition_systemd_unit.kubelet_worker.id}",
    "${data.ignition_systemd_unit.proxy.id}",
  ]
}

data "template_file" "kubelet_worker" {
  template = "${file("${path.module}/service/kubelet.service")}"

  vars {
    flags = "--node-labels=node-role.kubernetes.io/worker"
  }
}

data "ignition_systemd_unit" "kubelet_worker" {
  content = "${data.template_file.kubelet_worker.rendered}"
  enabled = true
  name    = "kubelet.service"
}
