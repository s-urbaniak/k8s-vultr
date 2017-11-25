resource "tls_private_key" "apiserver" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "apiserver" {
  key_algorithm   = "${tls_private_key.apiserver.algorithm}"
  private_key_pem = "${tls_private_key.apiserver.private_key_pem}"

  subject {
    common_name  = "kube-apiserver"
    organization = "kube-master"
  }

  dns_names = [
    "api-${local.cluster_name}.${var.cluster_base_domain}",
    "${data.template_file.master_fqdn.*.rendered}",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster.local",
  ]

  ip_addresses = [
    "10.3.0.1",
  ]
}

resource "tls_locally_signed_cert" "apiserver" {
  cert_request_pem = "${tls_cert_request.apiserver.cert_request_pem}"

  ca_key_algorithm      = "${tls_self_signed_cert.kube_ca.key_algorithm}"
  ca_private_key_pem    = "${tls_private_key.kube_ca.private_key_pem}"
  ca_cert_pem           = "${tls_self_signed_cert.kube_ca.cert_pem}"
  validity_period_hours = "${var.validity_period}"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

// api -> etcd client keys

resource "tls_private_key" "api_etcd_client" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "api_etcd_client" {
  key_algorithm   = "${tls_private_key.api_etcd_client.algorithm}"
  private_key_pem = "${tls_private_key.api_etcd_client.private_key_pem}"

  subject {
    common_name  = "api"
    organization = "etcd"
  }

  dns_names = ["${data.template_file.master_fqdn.*.rendered}"]
}

resource "tls_locally_signed_cert" "api_etcd_client" {
  ca_cert_pem           = "${tls_self_signed_cert.etcd_ca.cert_pem}"
  ca_key_algorithm      = "${tls_self_signed_cert.etcd_ca.key_algorithm}"
  ca_private_key_pem    = "${tls_private_key.etcd_ca.private_key_pem}"
  cert_request_pem      = "${tls_cert_request.api_etcd_client.cert_request_pem}"
  validity_period_hours = "${var.validity_period}"

  allowed_uses = [
    "key_encipherment",
    "client_auth",
  ]
}

// api -> kubelet client keys

resource "tls_private_key" "api_kubelet" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "api_kubelet" {
  key_algorithm   = "${tls_private_key.api_kubelet.algorithm}"
  private_key_pem = "${tls_private_key.api_kubelet.private_key_pem}"

  subject {
    common_name  = "apiserver"
    organization = "system:masters"
  }
}

resource "tls_locally_signed_cert" "api_kubelet" {
  cert_request_pem = "${tls_cert_request.api_kubelet.cert_request_pem}"

  ca_key_algorithm      = "${tls_self_signed_cert.kube_ca.key_algorithm}"
  ca_private_key_pem    = "${tls_private_key.kube_ca.private_key_pem}"
  ca_cert_pem           = "${tls_self_signed_cert.kube_ca.cert_pem}"
  validity_period_hours = "${var.validity_period}"

  allowed_uses = [
    "key_encipherment",
    "client_auth",
  ]
}
