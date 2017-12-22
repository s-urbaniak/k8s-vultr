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
  - ip: ${vultr_instance.master.*.ipv4_private_address[count.index]}
EOF
}

data "template_file" "master_endpoints" {
  count = "${var.master_count}"

  template = <<EOF
  - ip: ${vultr_instance.master.*.ipv4_private_address[count.index]}
    nodeName: ${vultr_instance.master.*.name[count.index]}
EOF
}

resource "template_dir" "manifests" {
  source_dir      = "${path.module}/manifests"
  destination_dir = "./generated/manifests"

  vars = {
    ip_list                    = "${join("\n", data.template_file.etcd_endpoints.*.rendered)}"
    scheduler_ip_list          = "${join("\n", data.template_file.master_endpoints.*.rendered)}"
    controller_manager_ip_list = "${join("\n", data.template_file.master_endpoints.*.rendered)}"
    etcd_server_name           = "${data.template_file.master_fqdn.*.rendered[0]}"
    oidc_client_id             = "${var.oidc_client_id}"
    oidc_client_secret         = "${var.oidc_client_secret}"
    oidc_cookie_secret         = "${var.oidc_cookie_secret}"
    cluster_base_domain        = "${var.cluster_base_domain}"
  }
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
