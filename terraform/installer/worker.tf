resource "local_file" "customize_worker_machines" {
  depends_on = [
    data.local_file.infra_id
  ]

  count           = length(var.availability_zones)
  filename        = "${path.root}/clusterconfig/openshift/99_openshift-cluster-api_worker-machines-${count.index}.yaml"
  file_permission = "0644"

  content = <<-EOT
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  labels:
    machine.openshift.io/cluster-api-cluster: ${trimspace(data.local_file.infra_id.content)}
  name: ${trimspace(data.local_file.infra_id.content)}-worker-${var.availability_zones[count.index]}
  namespace: openshift-machine-api
spec:
  replicas: 0
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: ${trimspace(data.local_file.infra_id.content)}
      machine.openshift.io/cluster-api-machineset: ${trimspace(data.local_file.infra_id.content)}-worker-${var.availability_zones[count.index]}
  template:
    metadata:
      name: ${data.local_file.infra_id.content}-worker-${count.index}
      labels:
        machine.openshift.io/cluster-api-cluster: ${trimspace(data.local_file.infra_id.content)}
        machine.openshift.io/cluster-api-machine-role: worker
        machine.openshift.io/cluster-api-machine-type: worker
        machine.openshift.io/cluster-api-machineset: ${trimspace(data.local_file.infra_id.content)}-worker-${var.availability_zones[count.index]}
    spec:
      metadata:
        creationTimestamp: null
        name: ${data.local_file.infra_id.content}-worker-${count.index}
        labels:
          node-role.kubernetes.io/worker: ""
      providerSpec:
        value:
          spotMarketOptions:
            maxPrice: 0.03
          ami:
            id: ami-09e7ca07ec8aa6983
          apiVersion: awsproviderconfig.openshift.io/v1beta1
          blockDevices:
            - ebs:
                iops: 0
                volumeSize: 120
                volumeType: gp2
          credentialsSecret:
            name: aws-cloud-credentials
          deviceIndex: 0
          iamInstanceProfile:
            id: ${trimspace(data.local_file.infra_id.content)}-worker-profile
          instanceType: ${var.worker_instance_type}
          kind: AWSMachineProviderConfig
          placement:
            availabilityZone: ${var.availability_zones[count.index]}
            region: ${var.region}
          securityGroups:
            - filters:
                - name: tag:Name
                  values:
                    - ${trimspace(data.local_file.infra_id.content)}-worker-sg
          subnet:
            filters:
              - name: tag:Name
                values:
                  - ${trimspace(data.local_file.infra_id.content)}-private-${var.availability_zones[count.index]}
          tags:
            - name: kubernetes.io/cluster/${trimspace(data.local_file.infra_id.content)}
              value: owned
            - name : Name
              value: ${data.local_file.infra_id.content}-worker-${count.index}
            - name: Zone
              value: ${var.availability_zones[count.index]}
          userDataSecret:
            name: worker-user-data
EOT
}