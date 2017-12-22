variable "master_count" {
  type    = "string"
  default = "1"
}

variable "worker_count" {
  type    = "string"
  default = "1"
}

variable "ssh_authorized_key_list" {
  type = "list"
}

resource "random_id" "cluster" {
  byte_length = 2
}

locals {
  cluster_name = "${var.cluster_name == "" ? random_id.cluster.hex : var.cluster_name}"
}

variable "cluster_name" {
  type    = "string"
  default = ""
}

variable "validity_period" {
  type    = "string"
  default = 26280
}

variable "cluster_base_domain" {
  type = "string"
}

variable "container_images" {
  description = "(internal) Container images to use"
  type        = "map"

  default = {
    etcd = "quay.io/coreos/etcd:v3.2.9"
  }
}

variable "hyperkube_url" {
  type = "string"
}

variable "service_cidr" {
  type    = "string"
  default = "10.3.0.0/16"
}

variable "oauth_client_id" {
  type = "string"
}

variable "oauth_client_secret" {
  type = "string"
}

variable "oauth_cookie_secret" {
  type = "string"
}
