## Prerequisites

    1. openshift-install binary is in path
    2. domain name hosted in AWS route53 

## Installation instructions

    1. Create an ssh key for the installer using ssh-keygen -t ed25519 -N '' -f <path>/<file_name>
    2. Updte the terraform.tfvars file with base domain and the path for the ssh public key
    3. Download the openshift installer from this page https://github.com/openshift/okd/tags
    4. Add the installer openshift-installer to the executable path, for example /usr/local/bin
    5. Setup aws cli and a default profile with the access credentials
    6. Run tf apply to install the cluster on AWS

## Check installation progress
    
    1. cd clusterconfig
    2. Wait for bootstrapping to complete => openshift-install wait-for bootstrap-complete --dir .
    3. Once bootstrapping is complete you can remove bootstrap instance using tf destroy -target=module.bootstrap -auto-approve
    4. check cluster operators status using watch -n1 oc get clusteroperators
    5. Wait for installation to complete => openshift-install wait-for install-complete --dir .
    6. Console should be available in https://console-openshift-console.apps.<cluster_name>.<base_domain>