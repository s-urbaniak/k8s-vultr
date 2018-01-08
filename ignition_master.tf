data "ignition_config" "master" {
  count = "${var.master_count}"

  files = [
    "${data.ignition_file.etcd_ca.id}",
    "${data.ignition_file.etcd_server_key.id}",
    "${data.ignition_file.etcd_server_crt.id}",
    "${data.ignition_file.etcd_peer_key.id}",
    "${data.ignition_file.etcd_peer_crt.id}",
    "${data.ignition_file.api_etcd_client_crt.id}",
    "${data.ignition_file.api_etcd_client_key.id}",
    "${data.ignition_file.ca_crt.id}",
    "${data.ignition_file.ca_key.id}",
    "${data.ignition_file.apiserver_key.id}",
    "${data.ignition_file.apiserver_crt.id}",
    "${data.ignition_file.service_account_crt.id}",
    "${data.ignition_file.service_account_key.id}",
    "${data.ignition_file.kubeconfig.id}",
    "${data.ignition_file.api_kubelet_client_key.id}",
    "${data.ignition_file.api_kubelet_client_crt.id}",
    "${data.ignition_file.hostname.id}",
    "${data.ignition_file.resolv_conf.id}",
    "${data.ignition_file.proxy_client_crt.id}",
    "${data.ignition_file.proxy_client_key.id}",
  ]

  systemd = [
    "${data.ignition_systemd_unit.etcd.*.id[count.index]}",
    "${data.ignition_systemd_unit.hyperkube_download.id}",
    "${data.ignition_systemd_unit.apiserver.*.id[count.index]}",
    "${data.ignition_systemd_unit.kubelet.id}",
    "${data.ignition_systemd_unit.proxy.id}",
    "${data.ignition_systemd_unit.scheduler.id}",
    "${data.ignition_systemd_unit.controller_manager.id}",
    "${data.ignition_systemd_unit.vultr_metadata.id}",
  ]

  networkd = [
    "${data.ignition_networkd_unit.eth1.id}",
  ]

  users = [
    "${data.ignition_user.core.id}",
  ]
}

data "ignition_file" "resolv_conf" {
  path       = "/etc/resolv.conf"
  mode       = 0644
  uid        = 0
  filesystem = "root"

  content {
    content = <<EOF
search ${var.cluster_base_domain}
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
  }
}

data "ignition_file" "hostname" {
  count      = "${var.master_count}"
  path       = "/etc/hostname"
  mode       = 0644
  uid        = 0
  filesystem = "root"

  content {
    content = "master-${local.cluster_name}-${count.index}"
  }
}

// eth1 private network card setup

data "ignition_networkd_unit" "eth1" {
  name = "eth1.network"

  // PRIVATE_IPV4 will be replaced by the install.service systemd service unit
  content = <<EOF
[Match]
Name=eth1

[Network]
Address=PRIVATE_IPV4/16

[Link]
MTUBytes=1450
EOF
}

// metadata service

data "ignition_systemd_unit" "vultr_metadata" {
  content = "${file("${path.module}/systemd/vultr-metadata.service")}"
  enabled = true
  name    = "vultr-metadata.service"
}

// core user

data "ignition_user" "core" {
  name                = "core"
  ssh_authorized_keys = "${var.ssh_authorized_key_list}"
}

// hyperkube / apiserver

data "template_file" "hyperkube" {
  template = "${file("${path.module}/systemd/hyperkube-download.service")}"

  vars = {
    hyperkube_url = "${var.hyperkube_url}"
  }
}

data "ignition_systemd_unit" "hyperkube_download" {
  content = "${data.template_file.hyperkube.rendered}"
  enabled = true
  name    = "hyperkube-download.service"
}

data "template_file" "apiserver" {
  count    = "${var.master_count}"
  template = "${file("${path.module}/systemd/apiserver.service")}"

  vars = {
    service_cidr   = "${var.service_cidr}"
    etcd_servers   = "${join(",", data.template_file.advertise_client_url.*.rendered)}"
    oidc_client_id = "${var.oidc_client_id}"
  }
}

data "ignition_systemd_unit" "apiserver" {
  count   = "${var.master_count}"
  content = "${data.template_file.apiserver.*.rendered[count.index]}"
  enabled = true
  name    = "apiserver.service"
}

data "template_file" "kubelet" {
  template = "${file("${path.module}/systemd/kubelet.service")}"

  vars {
    flags = "--node-labels=node-role.kubernetes.io/master --register-with-taints=node-role.kubernetes.io/master=:NoSchedule"
  }
}

data "ignition_systemd_unit" "kubelet" {
  content = "${data.template_file.kubelet.rendered}"
  enabled = true
  name    = "kubelet.service"
}

data "template_file" "proxy" {
  template = "${file("${path.module}/systemd/proxy.service")}"
}

data "ignition_systemd_unit" "proxy" {
  content = "${data.template_file.proxy.rendered}"
  enabled = true
  name    = "proxy.service"
}

data "template_file" "scheduler" {
  template = "${file("${path.module}/systemd/scheduler.service")}"
}

data "ignition_systemd_unit" "scheduler" {
  content = "${data.template_file.scheduler.rendered}"
  enabled = true
  name    = "scheduler.service"
}

data "template_file" "controller_manager" {
  template = "${file("${path.module}/systemd/controller-manager.service")}"
}

data "ignition_systemd_unit" "controller_manager" {
  content = "${data.template_file.controller_manager.rendered}"
  enabled = true
  name    = "controller-manager.service"
}

// kube certs

data "ignition_file" "api_etcd_client_crt" {
  path       = "/etc/kubernetes/tls/api_etcd_client.crt"
  mode       = 0644
  filesystem = "root"

  content {
    content = "${tls_locally_signed_cert.api_etcd_client.cert_pem}"
  }
}

data "ignition_file" "api_etcd_client_key" {
  path       = "/etc/kubernetes/tls/api_etcd_client.key"
  mode       = 0400
  filesystem = "root"

  content {
    content = "${tls_private_key.api_etcd_client.private_key_pem}"
  }
}

data "ignition_file" "ca_crt" {
  path       = "/etc/kubernetes/tls/ca.crt"
  mode       = 0644
  filesystem = "root"

  content {
    content = "${tls_self_signed_cert.kube_ca.cert_pem}"
  }
}

data "ignition_file" "ca_key" {
  path       = "/etc/kubernetes/tls/ca.key"
  mode       = 0400
  filesystem = "root"

  content {
    content = "${tls_private_key.kube_ca.private_key_pem}"
  }
}

data "ignition_file" "apiserver_key" {
  path       = "/etc/kubernetes/tls/apiserver.key"
  mode       = 0400
  filesystem = "root"

  content {
    content = "${tls_private_key.apiserver.private_key_pem}"
  }
}

data "ignition_file" "apiserver_crt" {
  path       = "/etc/kubernetes/tls/apiserver.crt"
  mode       = 0644
  filesystem = "root"

  content {
    content = "${tls_locally_signed_cert.apiserver.cert_pem}"
  }
}

data "ignition_file" "api_kubelet_client_key" {
  path       = "/etc/kubernetes/tls/api_kubelet_client.key"
  mode       = 0400
  filesystem = "root"

  content {
    content = "${tls_private_key.api_kubelet.private_key_pem}"
  }
}

data "ignition_file" "api_kubelet_client_crt" {
  path       = "/etc/kubernetes/tls/api_kubelet_client.crt"
  mode       = 0644
  filesystem = "root"

  content {
    content = "${tls_locally_signed_cert.api_kubelet.cert_pem}"
  }
}

// etcd certs

data "ignition_file" "etcd_ca" {
  path       = "/etc/ssl/etcd/ca.crt"
  mode       = 0644
  uid        = 232
  gid        = 232
  filesystem = "root"

  content {
    content = "${tls_self_signed_cert.etcd_ca.cert_pem}"
  }
}

data "ignition_file" "etcd_server_key" {
  path       = "/etc/ssl/etcd/server.key"
  mode       = 0400
  uid        = 232
  gid        = 232
  filesystem = "root"

  content {
    content = "${tls_private_key.etcd_server.private_key_pem}"
  }
}

data "ignition_file" "etcd_server_crt" {
  path       = "/etc/ssl/etcd/server.crt"
  mode       = 0400
  uid        = 232
  gid        = 232
  filesystem = "root"

  content {
    content = "${tls_locally_signed_cert.etcd_server.cert_pem}"
  }
}

data "ignition_file" "etcd_peer_key" {
  path       = "/etc/ssl/etcd/peer.key"
  mode       = 0400
  uid        = 232
  gid        = 232
  filesystem = "root"

  content {
    content = "${tls_private_key.etcd_peer.private_key_pem}"
  }
}

data "ignition_file" "etcd_peer_crt" {
  path       = "/etc/ssl/etcd/peer.crt"
  mode       = 0400
  uid        = 232
  gid        = 232
  filesystem = "root"

  content {
    content = "${tls_locally_signed_cert.etcd_peer.cert_pem}"
  }
}

// etcd

data "template_file" "etcd_name" {
  count    = "${var.master_count}"
  template = "${data.template_file.master_fqdn.*.rendered[count.index]}"
}

data "template_file" "advertise_client_url" {
  count    = "${var.master_count}"
  template = "https://${data.template_file.etcd_name.*.rendered[count.index]}:2379"
}

data "template_file" "initial_advertise_peer_url" {
  count    = "${var.master_count}"
  template = "https://${data.template_file.etcd_name.*.rendered[count.index]}:2380"
}

data "template_file" "initial_cluster" {
  count    = "${var.master_count}"
  template = "${data.template_file.etcd_name.*.rendered[count.index]}=${data.template_file.initial_advertise_peer_url.*.rendered[count.index]}"
}

data "template_file" "etcd" {
  count    = "${var.master_count}"
  template = "${file("${path.module}/systemd/40-etcd-cluster.conf")}"

  vars = {
    advertise_client_urls       = "${data.template_file.advertise_client_url.*.rendered[count.index]}"
    container_image             = "${var.container_images["etcd"]}"
    initial_advertise_peer_urls = "${data.template_file.initial_advertise_peer_url.*.rendered[count.index]}"
    initial_cluster             = "${join(",", data.template_file.initial_cluster.*.rendered)}"
    name                        = "${data.template_file.etcd_name.*.rendered[count.index]}"
  }
}

data "ignition_systemd_unit" "etcd" {
  count   = "${var.master_count}"
  name    = "etcd-member.service"
  enabled = true

  dropin = [
    {
      name    = "40-etcd-cluster.conf"
      content = "${data.template_file.etcd.*.rendered[count.index]}"
    },
  ]
}

data "ignition_file" "service_account_crt" {
  path       = "/etc/kubernetes/tls/service_account.crt"
  mode       = 0644
  filesystem = "root"

  content {
    content = "${tls_private_key.service_account.public_key_pem}"
  }
}

data "ignition_file" "service_account_key" {
  path       = "/etc/kubernetes/tls/service_account.key"
  mode       = 0400
  filesystem = "root"

  content {
    content = "${tls_private_key.service_account.private_key_pem}"
  }
}

data "ignition_file" "proxy_client_crt" {
  path       = "/etc/kubernetes/tls/proxy_client.crt"
  mode       = 0644
  filesystem = "root"

  content {
    content = "${tls_locally_signed_cert.proxy_client.cert_pem}"
  }
}

data "ignition_file" "proxy_client_key" {
  path       = "/etc/kubernetes/tls/proxy_client.key"
  mode       = 0400
  filesystem = "root"

  content {
    content = "${tls_private_key.proxy_client.private_key_pem}"
  }
}

data "ignition_file" "kubeconfig" {
  path       = "/etc/kubernetes/tls/kubeconfig"
  mode       = 0400
  filesystem = "root"

  content {
    content = "${data.template_file.kubeconfig.rendered}"
  }
}
