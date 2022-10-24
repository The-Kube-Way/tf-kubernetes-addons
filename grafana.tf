locals {
  grafana = merge(
    local.helm_defaults,
    {
      enabled                = false
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "grafana")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "grafana")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "grafana")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "grafana")].version
      namespace              = "default"
      create_ns              = false
      cpu_limit              = "200m"
      memory_limit           = "256Mi"
      root_url               = ""
      fix_volume_permissions = false
      users_viewers_can_edit = false # Allow viewers to use Explore and perform temporary edits on panels
    },
    var.grafana
  )

  values_grafana = <<VALUES
    admin:
      user: "admin"
      password: ""

    grafana:
      updateStrategy:
        type: Recreate
      podSecurityContext:
        runAsNonRoot: ${!local.grafana["fix_volume_permissions"]}  
      resources:
        requests:
           cpu: 50m
           memory: 256Mi
        limits:
          cpu: ${local.grafana["cpu_limit"]}
          memory: ${local.grafana["memory_limit"]}
      podAnnotations:
        backup.velero.io/backup-volumes: data
      extraEnvVars:
        - name: GF_ANALYTICS_REPORTING_ENABLED
          value: "false"
        - name: GF_ANALYTICS_CHECK_FOR_UPDATES
          value: "false"
        - name: GF_ANALYTICS_CHECK_FOR_PLUGIN_UPDATES
          value: "false"
        - name: GF_USERS_USER_INVITE_MAX_LIFETIME_DURATION
          value: "7d"
        - name: GF_USERS_VIEWERS_CAN_EDIT
          value: "${local.grafana["users_viewers_can_edit"]}"
        %{if length(local.grafana["root_url"]) > 0}
        - name: GF_SERVER_ROOT_URL
          value: ${local.grafana["root_url"]}
        %{endif}

    persistence:
      enabled: true

    volumePermissions:
      enabled: ${local.grafana["fix_volume_permissions"]}
VALUES
}


resource "kubernetes_namespace" "grafana" {
  count = local.grafana["enabled"] && local.grafana["create_ns"] ? 1 : 0
  metadata {
    name = local.grafana["namespace"]
    labels = {
      name = local.grafana["namespace"]
    }
  }
}


resource "helm_release" "grafana" {
  count                 = local.grafana["enabled"] ? 1 : 0
  namespace             = local.grafana["namespace"]
  repository            = local.grafana["repository"]
  name                  = local.grafana["name"]
  chart                 = local.grafana["chart"]
  version               = local.grafana["chart_version"]
  timeout               = local.grafana["timeout"]
  force_update          = local.grafana["force_update"]
  recreate_pods         = local.grafana["recreate_pods"]
  wait                  = local.grafana["wait"]
  atomic                = local.grafana["atomic"]
  cleanup_on_fail       = local.grafana["cleanup_on_fail"]
  dependency_update     = local.grafana["dependency_update"]
  disable_crd_hooks     = local.grafana["disable_crd_hooks"]
  disable_webhooks      = local.grafana["disable_webhooks"]
  render_subchart_notes = local.grafana["render_subchart_notes"]
  replace               = local.grafana["replace"]
  reset_values          = local.grafana["reset_values"]
  reuse_values          = local.grafana["reuse_values"]
  skip_crds             = local.grafana["skip_crds"]
  verify                = local.grafana["verify"]
  values = [
    local.values_grafana,
    local.grafana["extra_values"]
  ]

  depends_on = [
    kubernetes_namespace.grafana
  ]
}
