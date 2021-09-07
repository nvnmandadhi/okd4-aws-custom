data "template_file" "install_config" {
  template = <<-EOT
apiVersion: v1
baseDomain: "${var.base_domain}"
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform: {}
  replicas: 0
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform: {}
  replicas: 3
metadata:
  creationTimestamp: null
  name: "${var.cluster_name}"
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  aws:
    region: "${var.region}"
publish: External
pullSecret: '{"auths":{"fake":{"auth":"aWQ6cGFzcwo="}}}'
sshKey: "${trimspace(data.local_file.ssh_key.content)}"
EOT
}

resource "local_file" "install_config" {
  depends_on = [data.template_file.install_config]

  content  = data.template_file.install_config.rendered
  filename = "${path.root}/install-config.yaml"
}

resource "null_resource" "generate_manifests" {
  depends_on = [local_file.install_config]

  provisioner "local-exec" {
    command    = <<-EOT
        export GODEBUG=asyncpreemptoff=1
        aws s3 rm --recursive s3://${var.s3_state_bucket}/clusterconfig
        rm -fr "${path.root}/clusterconfig" >/dev/null
        rm -fr "${path.root}/clustermanifests" >/dev/null
        mkdir "${path.root}/clusterconfig"
        mv "${path.root}/install-config.yaml" "${path.root}/clusterconfig/install-config.yaml"
        openshift-install create manifests --dir "${path.root}/clusterconfig"
        mkdir "${path.root}/clustermanifests"
        for i in {0..2}; do rm -fr "${path.root}/clusterconfig/openshift/99_openshift-cluster-api_master-machines-$i.yaml"; done
        for i in {0..2}; do rm -fr "${path.root}/clusterconfig/openshift/99_openshift-cluster-api_worker-machineset-$i.yaml"; done
        ls -l "${path.root}/clusterconfig/openshift"
    EOT
    on_failure = fail
  }
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      rm -fr "${path.root}/clusterconfig" > /dev/null
      rm -fr "${path.root}/clustermanifests" > /dev/null
    EOT
  }
}

resource "null_resource" "generate_ignition_files" {
  depends_on = [
    null_resource.generate_manifests,
    local_file.customize_master_machines,
    local_file.customize_worker_machines,
    local_file.customize_infra_machines,
    local_file.cluster-monitoring-configmap,
    local_file.ingress_controller_config
  ]

  provisioner "local-exec" {
    command = <<-EOT
        cat "${path.root}/clusterconfig/openshift/99_openshift-cluster-api_master-machines-0.yaml"
        cat "${path.root}/clusterconfig/openshift/99_openshift-cluster-api_worker-machines-0.yaml"
        cat "${path.root}/clusterconfig/openshift/99_cluster-monitoring-configmap.yaml"
        ls -l "${path.root}/clusterconfig/openshift"
        cp -r "${path.root}/clusterconfig" "${path.root}/clustermanifests"
        export GODEBUG=asyncpreemptoff=1
        openshift-install create ignition-configs --dir "${path.root}/clusterconfig"
        aws s3 cp --recursive --exclude ".*" "${path.root}/clusterconfig" s3://${var.s3_state_bucket}/clusterconfig
    EOT
  }
}

resource "null_resource" "get_infra_id" {
  depends_on = [
    null_resource.generate_manifests
  ]

  provisioner "local-exec" {
    when    = create
    command = <<-EOT
      cat ${path.root}/clusterconfig/.openshift_install_state.json | jq -r ".\"*installconfig.ClusterID\".InfraID" | tr -d '\n' > ${path.module}/infraID
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      rm -rf ${path.module}/infraID
    EOT
  }
}

resource "aws_s3_bucket" "ignition" {
  bucket = trimspace(data.local_file.infra_id.content)
}

resource "aws_s3_bucket_object" "bootstrap_ign" {
  depends_on = [null_resource.generate_ignition_files]

  bucket       = aws_s3_bucket.ignition.id
  key          = "bootstrap.ign"
  acl          = "public-read"
  content_type = "text/plain"
  content      = data.local_file.bootstrap_ign.content
}

resource "aws_s3_bucket_object" "master_ign" {
  depends_on = [null_resource.generate_ignition_files]

  bucket       = aws_s3_bucket.ignition.id
  key          = "master.ign"
  acl          = "public-read"
  content_type = "text/plain"
  content      = data.local_file.master_ign.content
}

resource "aws_s3_bucket_object" "worker_ign" {
  depends_on = [null_resource.generate_ignition_files]

  bucket       = aws_s3_bucket.ignition.id
  key          = "worker.ign"
  acl          = "public-read"
  content_type = "text/plain"
  content      = data.local_file.worker_ign.content
}

data "local_file" "infra_id" {
  depends_on = [null_resource.get_infra_id]

  filename = "${path.module}/infraID"
}

data "local_file" "bootstrap_ign" {
  depends_on = [null_resource.generate_ignition_files]

  filename = "${path.root}/clusterconfig/bootstrap.ign"
}

data "local_file" "master_ign" {
  depends_on = [null_resource.generate_ignition_files]

  filename = "${path.root}/clusterconfig/master.ign"
}

data "local_file" "worker_ign" {
  depends_on = [null_resource.generate_ignition_files]

  filename = "${path.root}/clusterconfig/worker.ign"
}

data "local_file" "ssh_key" {
  filename = var.ssh_public_key_location
}

output "infraID" {
  value = trimspace(data.local_file.infra_id.content)
}

output "ignition_bucket_id" {
  value = aws_s3_bucket.ignition.id
}