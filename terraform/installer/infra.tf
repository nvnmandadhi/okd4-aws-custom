resource "local_file" "customize_infra_machines" {
  depends_on = [
    data.local_file.infra_id
  ]

  count           = length([var.availability_zones[0]])
  filename        = "${path.root}/clusterconfig/openshift/99_openshift-cluster-api_infra-machines-${count.index}.yaml"
  file_permission = "0644"

  content = <<-EOT
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  labels:
    machine.openshift.io/cluster-api-cluster: ${trimspace(data.local_file.infra_id.content)}
  name: ${trimspace(data.local_file.infra_id.content)}-infra-${var.availability_zones[count.index]}
  namespace: openshift-machine-api
spec:
  replicas: 1
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: ${trimspace(data.local_file.infra_id.content)}
      machine.openshift.io/cluster-api-machineset: ${trimspace(data.local_file.infra_id.content)}-infra-${var.availability_zones[count.index]}
  template:
    metadata:
      name: ${data.local_file.infra_id.content}-infra-${count.index}
      labels:
        machine.openshift.io/cluster-api-cluster: ${trimspace(data.local_file.infra_id.content)}
        machine.openshift.io/cluster-api-machine-role: infra
        machine.openshift.io/cluster-api-machine-type: infra
        machine.openshift.io/cluster-api-machineset: ${trimspace(data.local_file.infra_id.content)}-infra-${var.availability_zones[count.index]}
    spec:
      metadata:
        creationTimestamp: null
        name: ${data.local_file.infra_id.content}-infra-${count.index}
        labels:
          node-role.kubernetes.io/infra: ""
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
                volumeSize: 30
                volumeType: gp2
          credentialsSecret:
            name: aws-cloud-credentials
          deviceIndex: 0
          iamInstanceProfile:
            id: ${trimspace(data.local_file.infra_id.content)}-worker-profile
          instanceType: ${var.infra_instance_type}
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
              value: ${data.local_file.infra_id.content}-infra-${count.index}
            - name: Zone
              value: ${var.availability_zones[count.index]}
          userDataSecret:
            name: worker-user-data
EOT
}

resource "local_file" "cluster-monitoring-configmap" {
  depends_on = [
    null_resource.generate_manifests
  ]

  filename        = "${path.root}/clusterconfig/openshift/99_cluster-monitoring-configmap.yaml"
  file_permission = "0644"
  content         = <<-EOT
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |+
    alertmanagerMain:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    prometheusK8s:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    prometheusOperator:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    grafana:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    k8sPrometheusAdapter:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    kubeStateMetrics:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    telemeterClient:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    openshiftStateMetrics:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    thanosQuerier:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
EOT
}

resource "local_file" "ingress_controller_config" {
  depends_on = [
    null_resource.generate_manifests
  ]

  filename        = "${path.root}/clusterconfig/openshift/99_cluster-ingress-controller.yml"
  file_permission = "0644"

  content = <<-EOT
apiVersion: operator.openshift.io/v1
kind: IngressController
metadata:
  name: default
  namespace: openshift-ingress-operator
spec:
  domain: apps.${var.cluster_name}.${var.base_domain}
  endpointPublishingStrategy:
    type: LoadBalancerService
    loadBalancer:
      scope: External
  nodePlacement:
    nodeSelector:
      matchLabels:
        node-role.kubernetes.io/infra: ""
  replicas: ${length([var.availability_zones[0]])}
EOT
}