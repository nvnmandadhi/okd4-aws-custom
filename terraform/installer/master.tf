resource "local_file" "customize_master_machines" {
  depends_on = [
    data.local_file.infra_id
  ]

  count           = length(var.availability_zones)
  filename        = "${path.root}/clusterconfig/openshift/99_openshift-cluster-api_master-machines-${count.index}.yaml"
  file_permission = "0644"

  content = <<-EOT
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  labels:
    machine.openshift.io/cluster-api-cluster: ${trimspace(data.local_file.infra_id.content)}
  name: ${trimspace(data.local_file.infra_id.content)}-master-${var.availability_zones[count.index]}
  namespace: openshift-machine-api
spec:
  replicas: 0
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: ${trimspace(data.local_file.infra_id.content)}
      machine.openshift.io/cluster-api-machineset: ${trimspace(data.local_file.infra_id.content)}-master-${var.availability_zones[count.index]}
  template:
    metadata:
      name: ${data.local_file.infra_id.content}-master-${count.index}
      labels:
        machine.openshift.io/cluster-api-cluster: ${trimspace(data.local_file.infra_id.content)}
        machine.openshift.io/cluster-api-machine-role: master
        machine.openshift.io/cluster-api-machine-type: master
        machine.openshift.io/cluster-api-machineset: ${trimspace(data.local_file.infra_id.content)}-master-${var.availability_zones[count.index]}
    spec:
      metadata:
        creationTimestamp: null
        name: ${data.local_file.infra_id.content}-master-${count.index}
        labels:
          node-role.kubernetes.io/master: ""
      providerSpec:
        value:
          spotMarketOptions:
            maxPrice: 0.039
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
            id: ${trimspace(data.local_file.infra_id.content)}-master-profile
          instanceType: ${var.instance_type}
          kind: AWSMachineProviderConfig
          placement:
            availabilityZone: ${var.availability_zones[count.index]}
            region: ${var.region}
          securityGroups:
            - filters:
                - name: tag:Name
                  values:
                    - ${trimspace(data.local_file.infra_id.content)}-master-sg
          subnet:
            filters:
              - name: tag:Name
                values:
                  - ${trimspace(data.local_file.infra_id.content)}-private-${var.availability_zones[count.index]}
          tags:
            - name: kubernetes.io/cluster/${trimspace(data.local_file.infra_id.content)}
              value: owned
            - name : Name
              value: ${data.local_file.infra_id.content}-master-${count.index}
            - name: Zone
              value: ${var.availability_zones[count.index]}
          userDataSecret:
            name: master-user-data
EOT
}