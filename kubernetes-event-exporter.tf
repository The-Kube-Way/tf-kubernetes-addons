locals {
  kubernetes_event_exporter = merge(
    local.helm_defaults,
    {
      enabled        = false
      name           = local.helm_dependencies[index(local.helm_dependencies.*.name, "kubernetes-event-exporter")].name
      chart          = local.helm_dependencies[index(local.helm_dependencies.*.name, "kubernetes-event-exporter")].name
      repository     = local.helm_dependencies[index(local.helm_dependencies.*.name, "kubernetes-event-exporter")].repository
      chart_version  = local.helm_dependencies[index(local.helm_dependencies.*.name, "kubernetes-event-exporter")].version
      namespace      = "kube-system"
      priority_class = "highest-priority"
    },
    var.kubernetes_event_exporter
  )

  values_kubernetes_event_exporter = <<VALUES
fullnameOverride: "event-exporter"
config:
  logLevel: info
  logFormat: json
  trottlePeriod: 5
  receivers:
    - name: "dump"
      stdout: {}
  route:
    routes:
      - match:
          - receiver: "dump"
resources:
  requests:
    cpu: 5m
    memory: 64Mi
  limits:
    cpu: 50m
    memory: 64Mi
priorityClassName: ${local.kubernetes_event_exporter["priority_class"]}
VALUES
}

resource "helm_release" "kubernetes_event_exporter" {
  count                 = local.kubernetes_event_exporter["enabled"] ? 1 : 0
  namespace             = local.kubernetes_event_exporter["namespace"]
  repository            = local.kubernetes_event_exporter["repository"]
  name                  = local.kubernetes_event_exporter["name"]
  chart                 = local.kubernetes_event_exporter["chart"]
  version               = local.kubernetes_event_exporter["chart_version"]
  timeout               = local.kubernetes_event_exporter["timeout"]
  force_update          = local.kubernetes_event_exporter["force_update"]
  recreate_pods         = local.kubernetes_event_exporter["recreate_pods"]
  wait                  = local.kubernetes_event_exporter["wait"]
  atomic                = local.kubernetes_event_exporter["atomic"]
  cleanup_on_fail       = local.kubernetes_event_exporter["cleanup_on_fail"]
  dependency_update     = local.kubernetes_event_exporter["dependency_update"]
  disable_crd_hooks     = local.kubernetes_event_exporter["disable_crd_hooks"]
  disable_webhooks      = local.kubernetes_event_exporter["disable_webhooks"]
  render_subchart_notes = local.kubernetes_event_exporter["render_subchart_notes"]
  replace               = local.kubernetes_event_exporter["replace"]
  reset_values          = local.kubernetes_event_exporter["reset_values"]
  reuse_values          = local.kubernetes_event_exporter["reuse_values"]
  skip_crds             = local.kubernetes_event_exporter["skip_crds"]
  verify                = local.kubernetes_event_exporter["verify"]
  values = [
    local.values_kubernetes_event_exporter,
    local.kubernetes_event_exporter["extra_values"]
  ]
}
