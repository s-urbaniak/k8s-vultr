resource "tls_private_key" "kube_ca" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "kube_ca" {
  key_algorithm   = "${tls_private_key.kube_ca.algorithm}"
  private_key_pem = "${tls_private_key.kube_ca.private_key_pem}"

  subject {
    common_name  = "kube-ca"
    organization = "k8s"
  }

  is_ca_certificate     = true
  validity_period_hours = "${var.validity_period}"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}

// admin cert stored in kubeconfig

resource "tls_private_key" "admin" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "admin" {
  key_algorithm   = "${tls_private_key.admin.algorithm}"
  private_key_pem = "${tls_private_key.admin.private_key_pem}"

  subject {
    common_name  = "admin"
    organization = "system:masters"
  }
}

resource "tls_locally_signed_cert" "admin" {
  cert_request_pem = "${tls_cert_request.admin.cert_request_pem}"

  ca_key_algorithm      = "${tls_self_signed_cert.kube_ca.key_algorithm}"
  ca_private_key_pem    = "${tls_private_key.kube_ca.private_key_pem}"
  ca_cert_pem           = "${tls_self_signed_cert.kube_ca.cert_pem}"
  validity_period_hours = "${var.validity_period}"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

resource "tls_private_key" "service_account" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

// kubelet https endpoint certs

resource "tls_private_key" "kubelet" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

// proxy client cert

resource "tls_private_key" "proxy_client" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "proxy_client" {
  key_algorithm   = "${tls_private_key.proxy_client.algorithm}"
  private_key_pem = "${tls_private_key.proxy_client.private_key_pem}"

  subject {
    common_name  = "kube"
    organization = "proxy_client"
  }
}

resource "tls_locally_signed_cert" "proxy_client" {
  cert_request_pem = "${tls_cert_request.proxy_client.cert_request_pem}"

  ca_key_algorithm      = "${tls_self_signed_cert.kube_ca.key_algorithm}"
  ca_private_key_pem    = "${tls_private_key.kube_ca.private_key_pem}"
  ca_cert_pem           = "${tls_self_signed_cert.kube_ca.cert_pem}"
  validity_period_hours = "${var.validity_period}"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}
