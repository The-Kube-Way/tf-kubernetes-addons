locals {
  falco = merge(
    local.helm_defaults,
    {
      enabled         = false
      name            = "falco"
      namespace       = "falco"
      driver_kind     = "module"
      priority_class  = "highest-priority"
      webui_enabled   = false
      service_monitor = true
    },
    var.falco
  )

  values_falco = <<VALUES
podPriorityClassName: ${local.falco["priority_class"]}
resources:
  requests:
    cpu: 20m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi

controller:
  kind: daemonset

driver:
  enabled: true
  kind: ${local.falco["driver_kind"]}

falcosidekick:
  enabled: true
  replicaCount: 1
  resources:
    requests:
      cpu: 20m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 256Mi
  webui:
    enabled: ${local.falco["webui_enabled"]}
    replicaCount: 1
  config:  # can be customized using extra_values
    debug: false
VALUES
}

resource "kubernetes_namespace" "falco" {
  count = local.falco["enabled"] ? 1 : 0
  metadata {
    name = local.falco["namespace"]
    labels = {
      name = local.falco["namespace"]
    }
  }
}

resource "kubernetes_manifest" "falco_service_monitor" {
  count = local.falco["enabled"] && local.falco["service_monitor"] ? 1 : 0
  manifest = {
    "apiVersion" : "monitoring.coreos.com/v1",
    "kind" : "ServiceMonitor",
    "metadata" : {
      "name" : "falcosidekick",
      "namespace" : local.falco["namespace"]
    },
    "spec" : {
      "endpoints" : [
        {
          "interval" : "60s",
          "targetPort" : "2801"
        }
      ],
      "selector" : {
        "matchLabels" : {
          "app.kubernetes.io/instance" : local.falco["name"],
          "app.kubernetes.io/name" : "falcosidekick"
        }
      }
    }
  }
}

resource "helm_release" "falco" {
  count                 = local.falco["enabled"] ? 1 : 0
  namespace             = local.falco["namespace"]
  name                  = local.falco["name"]
  repository            = "https://falcosecurity.github.io/charts"
  chart                 = "falco"
  version               = "2.4.6"
  timeout               = local.falco["timeout"]
  force_update          = local.falco["force_update"]
  recreate_pods         = local.falco["recreate_pods"]
  wait                  = local.falco["wait"]
  atomic                = local.falco["atomic"]
  cleanup_on_fail       = local.falco["cleanup_on_fail"]
  dependency_update     = local.falco["dependency_update"]
  disable_crd_hooks     = local.falco["disable_crd_hooks"]
  disable_webhooks      = local.falco["disable_webhooks"]
  render_subchart_notes = local.falco["render_subchart_notes"]
  replace               = local.falco["replace"]
  reset_values          = local.falco["reset_values"]
  reuse_values          = local.falco["reuse_values"]
  skip_crds             = local.falco["skip_crds"]
  verify                = local.falco["verify"]
  values = [
    local.values_falco,
    local.falco["extra_values"]
  ]

  depends_on = [
    kubernetes_namespace.falco
  ]
}
