locals {
  ingress-nginx = merge(
    local.helm_defaults,
    {
      enabled                          = false
      name                             = local.helm_dependencies[index(local.helm_dependencies.*.name, "ingress-nginx")].name
      chart                            = local.helm_dependencies[index(local.helm_dependencies.*.name, "ingress-nginx")].name
      repository                       = local.helm_dependencies[index(local.helm_dependencies.*.name, "ingress-nginx")].repository
      chart_version                    = local.helm_dependencies[index(local.helm_dependencies.*.name, "ingress-nginx")].version
      namespace                        = "ingress-nginx"
      cpu_limit                        = "500m"
      memory_limit                     = "256Mi"
      priority_class                   = "highest-priority"
      config                           = {}
      hostport                         = false
      extra_args                       = {}
      tcp                              = {}
      udp                              = {}
      kind                             = "DaemonSet"
      metrics                          = true
      service_monitor                  = local.kube-prometheus["enabled"]
      node_selector                    = {}
      termination_grace_period         = 300
      admission_webhook                = true
      admission_webhook_failure_policy = "Fail"
    },
    var.ingress-nginx
  )

  values_ingress-nginx = <<VALUES
controller:
  config: ${jsonencode(local.ingress-nginx["config"])}
  
  watchIngressWithoutClass: true

  hostPort:
    enabled: ${local.ingress-nginx["hostport"]}

  extraArgs: ${jsonencode(local.ingress-nginx["extra_args"])}

  kind: ${local.ingress-nginx["kind"]}

  service:
    type: ClusterIP

  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1

  terminationGracePeriodSeconds: ${local.ingress-nginx["termination_grace_period"]}

  nodeSelector: ${jsonencode(merge({ "kubernetes.io/os" : "linux" }, local.ingress-nginx["node_selector"]))}

  resources:
    limits:
      cpu: ${local.ingress-nginx["cpu_limit"]}
      memory: ${local.ingress-nginx["memory_limit"]}
    requests:
      cpu: 100m
      memory: 96Mi

  admissionWebhooks:
    enabled: ${local.ingress-nginx["admission_webhook"]}
    failurePolicy: ${local.ingress-nginx["admission_webhook_failure_policy"]}

  metrics:
    enabled: ${local.ingress-nginx["metrics"]}
    serviceMonitor:
      enabled: ${local.ingress-nginx["service_monitor"]}

  priorityClassName: ${local.ingress-nginx["priority_class"]}

tcp: ${jsonencode(local.ingress-nginx["tcp"])}

udp: ${jsonencode(local.ingress-nginx["udp"])}
VALUES
}


resource "kubernetes_namespace" "ingress_nginx" {
  count = local.ingress-nginx["enabled"] ? 1 : 0
  metadata {
    name = local.ingress-nginx["namespace"]
    labels = {
      name = local.ingress-nginx["namespace"]
    }
  }
}


resource "helm_release" "ingress_nginx" {
  count                 = local.ingress-nginx["enabled"] ? 1 : 0
  namespace             = local.ingress-nginx["namespace"]
  repository            = local.ingress-nginx["repository"]
  name                  = local.ingress-nginx["name"]
  chart                 = local.ingress-nginx["chart"]
  version               = local.ingress-nginx["chart_version"]
  timeout               = local.ingress-nginx["timeout"]
  force_update          = local.ingress-nginx["force_update"]
  recreate_pods         = local.ingress-nginx["recreate_pods"]
  wait                  = local.ingress-nginx["wait"]
  atomic                = local.ingress-nginx["atomic"]
  cleanup_on_fail       = local.ingress-nginx["cleanup_on_fail"]
  dependency_update     = local.ingress-nginx["dependency_update"]
  disable_crd_hooks     = local.ingress-nginx["disable_crd_hooks"]
  disable_webhooks      = local.ingress-nginx["disable_webhooks"]
  render_subchart_notes = local.ingress-nginx["render_subchart_notes"]
  replace               = local.ingress-nginx["replace"]
  reset_values          = local.ingress-nginx["reset_values"]
  reuse_values          = local.ingress-nginx["reuse_values"]
  skip_crds             = local.ingress-nginx["skip_crds"]
  verify                = local.ingress-nginx["verify"]
  values = [
    local.values_ingress-nginx,
    local.ingress-nginx["extra_values"]
  ]

  depends_on = [
    kubernetes_namespace.ingress_nginx,
    helm_release.kube-prometheus
  ]
}
