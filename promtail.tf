locals {
  promtail = merge(
    local.helm_defaults,
    {
      enabled       = false
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "promtail")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "promtail")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "promtail")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "promtail")].version
      namespace     = "loki"
      loki_address  = "http://loki.loki.svc.cluster.local:3100/loki/api/v1/push"
      cpu_limit     = "200m"
      memory_limit  = "64Mi"
    },
    var.promtail
  )

  values_promtail = <<VALUES
resources:
  limits:
    cpu: ${local.promtail["cpu_limit"]}
    memory: ${local.promtail["memory_limit"]}
  requests:
    cpu: 100m
    memory: 64Mi

serviceMonitor:
  enabled: true
  interval: "60s"

config:
  clients:
    - url: ${local.promtail["loki_address"]}
  snippets:
    pipelineStages:
      - cri: {}
      - match:
          selector: '{app="ingress-nginx"}'
          stages:
          - regex:
              expression: '^(?P<remote_addr>[\w\.]+) - (?P<remote_user>[^ ]*) \[(?P<time_local>.*)\] "(?P<method>[^ ]*) (?P<request>[^ ]*) (?P<protocol>[^ ]*)" (?P<status_code>[\d]+) (?P<body_bytes_sent>[\d]+) "(?P<http_referer>[^"]*)" "(?P<http_user_agent>[^"]*)" \d+ [\d\.]+ \[(?P<proxy_upstream_name>[\w\d-]*)\]'
          - labels:
              method: method
              status_code: status_code
              proxy_upstream_name: proxy_upstream_name
VALUES
}

resource "helm_release" "promtail" {
  count                 = local.promtail["enabled"] ? 1 : 0
  namespace             = local.promtail["namespace"]
  repository            = local.promtail["repository"]
  name                  = local.promtail["name"]
  chart                 = local.promtail["chart"]
  version               = local.promtail["chart_version"]
  timeout               = local.promtail["timeout"]
  force_update          = local.promtail["force_update"]
  recreate_pods         = local.promtail["recreate_pods"]
  wait                  = local.promtail["wait"]
  atomic                = local.promtail["atomic"]
  cleanup_on_fail       = local.promtail["cleanup_on_fail"]
  dependency_update     = local.promtail["dependency_update"]
  disable_crd_hooks     = local.promtail["disable_crd_hooks"]
  disable_webhooks      = local.promtail["disable_webhooks"]
  render_subchart_notes = local.promtail["render_subchart_notes"]
  replace               = local.promtail["replace"]
  reset_values          = local.promtail["reset_values"]
  reuse_values          = local.promtail["reuse_values"]
  skip_crds             = local.promtail["skip_crds"]
  verify                = local.promtail["verify"]
  values = [
    local.values_promtail,
    local.promtail["extra_values"]
  ]

  depends_on = [
    helm_release.kube-prometheus
  ]
}
