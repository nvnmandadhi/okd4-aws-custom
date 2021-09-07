variable "base_domain" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "infraID" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "api_external_lb_dns_name" {
  description = "External API's LB DNS name"
  type        = string
}

variable "api_external_lb_zone_id" {
  description = "External API's LB Zone ID"
  type        = string
}

variable "api_internal_lb_dns_name" {
  description = "Internal API's LB DNS name"
  type        = string
}

variable "api_internal_lb_zone_id" {
  description = "Internal API's LB Zone ID"
  type        = string
}