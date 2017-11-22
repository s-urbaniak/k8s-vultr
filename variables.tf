variable "master_count" {
  type    = "string"
  default = "1"
}

variable "master_size" {
  type    = "string"
  default = "1gb"
}

variable "worker_count" {
  type    = "string"
  default = "1"
}

variable "worker_size" {
  type    = "string"
  default = "1gb"
}

variable "image_name" {
  type    = "string"
  default = "coreos-stable"
}

variable "region" {
  type    = "string"
  default = "fra1"
}

variable "ssh_key_id_list" {
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

variable "hyperkube_sha512" {
  type = "string"
}

variable "service_cidr" {
  type    = "string"
  default = "10.3.0.0/16"
}
