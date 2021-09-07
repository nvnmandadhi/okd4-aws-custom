variable "master_count" {
  type = number
}

variable "availability_zones" {
  type        = list(string)
  description = "List of the availability zones in which to create the masters. The length of this list must match instance_count."
}

variable "az_to_subnet_id" {
  type        = map(string)
  description = "Map from availability zone name to the ID of the subnet in that availability zone"
}

variable "master_instance_profile_name" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "infraID" {
  type = string
}

variable "target_group_list" {
  type    = list(string)
  default = []
}

variable "master_security_groups" {
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