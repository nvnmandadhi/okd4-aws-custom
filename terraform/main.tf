provider "aws" {
  region = var.region
}

module "installer" {
  source                  = "./installer"
  cluster_name            = var.cluster_name
  base_domain             = var.base_domain
  region                  = var.region
  availability_zones      = var.availability_zones
  instance_type           = var.instance_type
  fedora_coreos_ami       = var.fedora_coreos_ami
  worker_instance_type    = var.worker_instance_type
  infra_instance_type     = var.infra_instance_type
  ssh_public_key_location = var.ssh_public_key_location
  s3_state_bucket         = var.s3_state_bucket
}

module "vpc" {
  source             = "./vpc"
  availability_zones = var.availability_zones
  cluster_name       = var.cluster_name
  infraID            = module.installer.infraID
  region             = var.region
}

module "iam" {
  source       = "./iam"
  cluster_name = "openshift"
  infraID      = module.installer.infraID
}

module "bootstrap" {
  source = "./bootstrap"
  # Use the ami from this link https://builds.coreos.fedoraproject.org/streams/stable.json
  fedora_coreos_ami          = var.fedora_coreos_ami
  infraID                    = module.installer.infraID
  instance_type              = var.instance_type
  target_group_list          = module.vpc.aws_lb_target_group_arns
  master_sg_id               = module.vpc.master_sg
  public_subnets             = module.vpc.public_subnets
  bootstrap_instance_profile = module.iam.bootstrap_instance_profile
  bootstrap_sg_id            = module.vpc.bootstrap_sg
  ignition_bucket_id         = module.installer.ignition_bucket_id
}

module "control_plane" {
  source                       = "./control-plane"
  master_count                 = 3
  fedora_coreos_ami            = var.fedora_coreos_ami
  master_instance_profile_name = module.iam.master_instance_profile
  infraID                      = module.installer.infraID
  private_subnets              = module.vpc.private_subnets
  target_group_list            = module.vpc.aws_lb_target_group_arns
  master_security_groups       = [module.vpc.master_sg]
  instance_type                = var.instance_type
  availability_zones           = var.availability_zones
  az_to_subnet_id              = module.vpc.az_to_private_subnet_id
  ignition_bucket_id           = module.installer.ignition_bucket_id
}

module "route53" {
  source                   = "./route53"
  base_domain              = var.base_domain
  cluster_name             = var.cluster_name
  infraID                  = module.installer.infraID
  vpc_id                   = module.vpc.vpc_id
  api_external_lb_dns_name = module.vpc.aws_lb_api_external_dns_name
  api_external_lb_zone_id  = module.vpc.aws_lb_api_external_zone_id
  api_internal_lb_dns_name = module.vpc.aws_lb_api_internal_dns_name
  api_internal_lb_zone_id  = module.vpc.aws_lb_api_internal_zone_id
}