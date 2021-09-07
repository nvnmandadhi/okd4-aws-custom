variable "cluster_name" {
  type = string
}

variable "base_domain" {
  type = string
}

variable "s3_state_bucket" {
  type = string
}

variable "s3_state_bucket_region" {
  type = string
}

variable "region" {
  type = string
}

variable "fedora_coreos_ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "worker_instance_type" {
  type = string
}

variable "infra_instance_type" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "ssh_public_key_location" {
  type = string
}