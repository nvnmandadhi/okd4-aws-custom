variable "infraID" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "bootstrap_instance_profile" {
  type = string
}

variable "bootstrap_sg_id" {
  type = string
}

variable "master_sg_id" {
  type = string
}

variable "target_group_list" {
  type = list(string)
}

variable "instance_type" {
  type = string
}

variable "fedora_coreos_ami" {
  type = string
}

variable "ignition_bucket_id" {
  type = string
}