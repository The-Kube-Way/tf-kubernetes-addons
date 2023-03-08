locals {
  cluster-autoscaler = merge(
    local.helm_defaults,
    {
      enabled            = false
      name               = "cluster-autoscaler"
      namespace          = "kube-system"
      cluster_name       = ""
      aws_region         = ""
      kubernetes_version = ""
      role-arn           = ""
    },
    var.cluster-autoscaler
  )

  values_cluster-autoscaler = <<-VALUES

autoDiscovery:
  clusterName: ${local.cluster-autoscaler["cluster_name"]}

  tags:
    - k8s.io/cluster-autoscaler/enabled
    - k8s.io/cluster-autoscaler/{{ .Values.autoDiscovery.clusterName }}
  # - kubernetes.io/cluster/{{ .Values.autoDiscovery.clusterName }}

cloudProvider: aws
awsRegion: ${local.cluster-autoscaler["aws_region"]}

extraArgs:
  logtostderr: true
  stderrthreshold: info
  v: 4
  # write-status-configmap: true
  # status-config-map-name: cluster-autoscaler-status
  # leader-elect: true
  # leader-elect-resource-lock: endpoints
  skip-nodes-with-local-storage: false
  expander: least-waste
  # scale-down-enabled: true
  # balance-similar-node-groups: true
  # min-replica-count: 0
  scale-down-utilization-threshold: 0.8
  # scale-down-non-empty-candidates-count: 30
  # max-node-provision-time: 15m0s
  # scan-interval: 10s
  scale-down-delay-after-add: 5m
  # scale-down-delay-after-delete: 0s
  # scale-down-delay-after-failure: 3m
  scale-down-unneeded-time: 5m
  skip-nodes-with-system-pods: false
  # balancing-ignore-label_1: first-label-to-ignore
  # balancing-ignore-label_2: second-label-to-ignore

fullnameOverride: "cluster-autoscaler"

image:
  tag: v${local.cluster-autoscaler["kubernetes_version"]}.0

nodeSelector: {}

priorityClassName: "system-cluster-critical"

rbac:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: ${local.cluster-autoscaler["role-arn"]}

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 10m
    memory: 64Mi

securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  runAsGroup: 1001

containerSecurityContext:
  capabilities:
    drop:
    - ALL

serviceMonitor:
  enabled: true
  interval: 20s
  namespace: ${local.cluster-autoscaler["namespace"]}
    VALUES
}

resource "helm_release" "cluster_autoscaler" {
  count                 = local.cluster-autoscaler["enabled"] ? 1 : 0
  namespace             = local.cluster-autoscaler["namespace"]
  name                  = local.cluster-autoscaler["name"]
  repository            = "https://kubernetes.github.io/autoscaler"
  chart                 = "cluster-autoscaler"
  version               = "9.26.0"
  timeout               = local.cluster-autoscaler["timeout"]
  force_update          = local.cluster-autoscaler["force_update"]
  recreate_pods         = local.cluster-autoscaler["recreate_pods"]
  wait                  = local.cluster-autoscaler["wait"]
  atomic                = local.cluster-autoscaler["atomic"]
  cleanup_on_fail       = local.cluster-autoscaler["cleanup_on_fail"]
  dependency_update     = local.cluster-autoscaler["dependency_update"]
  disable_crd_hooks     = local.cluster-autoscaler["disable_crd_hooks"]
  disable_webhooks      = local.cluster-autoscaler["disable_webhooks"]
  render_subchart_notes = local.cluster-autoscaler["render_subchart_notes"]
  replace               = local.cluster-autoscaler["replace"]
  reset_values          = local.cluster-autoscaler["reset_values"]
  reuse_values          = local.cluster-autoscaler["reuse_values"]
  skip_crds             = local.cluster-autoscaler["skip_crds"]
  verify                = local.cluster-autoscaler["verify"]
  values = [
    local.values_cluster-autoscaler,
    local.cluster-autoscaler["extra_values"]
  ]
}
