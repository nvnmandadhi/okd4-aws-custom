cluster_name            = "okd"
base_domain             = "<base_domain>"
s3_state_bucket         = "<existing_s3_bucket>"
s3_state_bucket_region  = "us-east-1"
region                  = "us-east-2"
fedora_coreos_ami       = "ami-09e7ca07ec8aa6983"
instance_type           = "m4.xlarge"
worker_instance_type    = "t2.large"
infra_instance_type     = "t2.large"
ssh_public_key_location = "<ssh_public_key_path>"
availability_zones      = ["us-east-2a", "us-east-2b", "us-east-2c"]