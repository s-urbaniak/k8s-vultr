data "template_file" "kubeconfig" {
  template = "${file("${path.module}/resources/kubeconfig")}"

  vars = {
    cluster_name = "cluster-${local.cluster_name}"
    kube_ca_cert = "${base64encode(tls_self_signed_cert.kube_ca.cert_pem)}"
    admin_cert   = "${base64encode(tls_locally_signed_cert.admin.cert_pem)}"
    admin_key    = "${base64encode(tls_private_key.admin.private_key_pem)}"
    server       = "https://api-${local.cluster_name}.${var.cluster_base_domain}"
  }
}

data "template_file" "etcd_endpoints" {
  count = "${var.master_count}"

  template = <<EOF
  - ip: ${digitalocean_droplet.master.*.ipv4_address_private[count.index]}
EOF
}

data "template_file" "master_endpoints" {
  count = "${var.master_count}"

  template = <<EOF
  - ip: ${digitalocean_droplet.master.*.ipv4_address_private[count.index]}
    nodeName: ${digitalocean_droplet.master.*.name[count.index]}
EOF
}

data "template_file" "etcd_prom" {
  template = "${file("${path.module}/manifests/07-etcd-prom.yaml.tpl")}"

  vars = {
    ip_list = "${join("\n", data.template_file.etcd_endpoints.*.rendered)}"
  }
}

data "template_file" "control_plane_endpoints" {
  template = "${file("${path.module}/manifests/06-control-plane-endpoints.yaml.tpl")}"

  vars = {
    scheduler_ip_list          = "${join("\n", data.template_file.master_endpoints.*.rendered)}"
    controller_manager_ip_list = "${join("\n", data.template_file.master_endpoints.*.rendered)}"
  }
}

resource "local_file" "etcd_prom" {
  content  = "${data.template_file.etcd_prom.rendered}"
  filename = "./generated/manifests/07-etcd-prom.yaml"
}

resource "local_file" "control_plane_endpoints" {
  content  = "${data.template_file.control_plane_endpoints.rendered}"
  filename = "./generated/manifests/06-control-plane-endpoints.yaml"
}

resource "local_file" "kubeconfig" {
  content  = "${data.template_file.kubeconfig.rendered}"
  filename = "./generated/kubeconfig"
}

resource "local_file" "etcd_client_pem" {
  content  = "${tls_locally_signed_cert.api_etcd_client.cert_pem}"
  filename = "./generated/etcd/etcd-client.pem"
}

resource "local_file" "etcd_client_key_pem" {
  content  = "${tls_private_key.api_etcd_client.private_key_pem}"
  filename = "./generated/etcd/etcd-client-key.pem"
}

resource "local_file" "etcd_ca" {
  content  = "${tls_self_signed_cert.etcd_ca.cert_pem}"
  filename = "./generated/etcd/ca.pem"
}
