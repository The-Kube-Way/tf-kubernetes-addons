locals {
  kube-prometheus = merge(
    local.helm_defaults,
    {
      enabled       = false
      name          = "prom1"
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "kube-prometheus")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "kube-prometheus")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "kube-prometheus")].version
      namespace                  = "prometheus"
      prometheus_cpu_limit       = "500m"
      prometheus_memory_limit    = "1Gi"
      alertmanager_cpu_limit     = "100m"
      alertmanager_memory_limit  = "128Mi"
      persistence                = false
      fix_volume_permissions     = false
      storage_class              = ""  # default if empty
      size                       = "4Gi"
      retention                  = "96h"
      alertmanager_config        = ""
      node_exporter_host_network = false  # If nodes are not in a bastion then hostNetwork to true exposes metrics to internet
      kube_proxy = true
    },
    var.kube-prometheus
  )

  values_kube-prometheus = <<VALUES
prometheus:
  retention: ${local.kube-prometheus["retention"]}
  resources:
    requests:
      cpu: 50m
      memory: 512Mi
    limits:
      cpu: ${local.kube-prometheus["prometheus_cpu_limit"]}
      memory: ${local.kube-prometheus["prometheus_memory_limit"]}
  persistence:
    enabled: ${local.kube-prometheus["persistence"]}
    %{if length(local.kube-prometheus["storage_class"]) > 0}storageClass: ${local.kube-prometheus["storage_class"]}%{endif}
    accessModes:
      - ReadWriteOnce
    size: ${local.kube-prometheus["size"]}
  %{if local.kube-prometheus["persistence"] && local.kube-prometheus["fix_volume_permissions"]}
  podSecurityContext:  # Fixing permissions require to run as root
    runAsUser: 0
  containerSecurityContext:
    runAsNonRoot: false
  prometheusConfigReloader:
    containerSecurityContext:
      runAsNonRoot: false
  initContainers:
   - name: fix-permissions
     image: busybox:latest
     imagePullPolicy: Always
     command: ['sh', '-c', 'chown -R 1001:1001 /prometheus && echo Permissions fixed']
     volumeMounts:
     - name: prometheus-${local.kube-prometheus["name"]}-kube-prometheus-prometheus-db
       mountPath: /prometheus
  %{endif}

alertmanager:
  requests:
    cpu: 10m
    memory: 128Mi
  limits:
    cpu: ${local.kube-prometheus["alertmanager_cpu_limit"]}
    memory: ${local.kube-prometheus["alertmanager_memory_limit"]}
  externalConfig: %{if length(local.kube-prometheus["alertmanager_config"]) > 0}true%{else}false%{endif}

node-exporter:
  hostNetwork: ${local.kube-prometheus["node_exporter_host_network"]}

kubeProxy:
  enabled: ${local.kube-prometheus["kube_proxy"]}

blackboxExporter:
  enabled: false
VALUES
}


resource "kubernetes_namespace" "prometheus" {
  count = local.kube-prometheus["enabled"] ? 1 : 0
  metadata {
    name = local.kube-prometheus["namespace"]
    labels = {
      name = local.kube-prometheus["namespace"]
    }
  }
}


resource "helm_release" "kube-prometheus" {
  count                 = local.kube-prometheus["enabled"] ? 1 : 0
  namespace             = local.kube-prometheus["namespace"]
  repository            = local.kube-prometheus["repository"]
  name                  = local.kube-prometheus["name"]
  chart                 = local.kube-prometheus["chart"]
  version               = local.kube-prometheus["chart_version"]
  timeout               = local.kube-prometheus["timeout"]
  force_update          = local.kube-prometheus["force_update"]
  recreate_pods         = local.kube-prometheus["recreate_pods"]
  wait                  = local.kube-prometheus["wait"]
  atomic                = local.kube-prometheus["atomic"]
  cleanup_on_fail       = local.kube-prometheus["cleanup_on_fail"]
  dependency_update     = local.kube-prometheus["dependency_update"]
  disable_crd_hooks     = local.kube-prometheus["disable_crd_hooks"]
  disable_webhooks      = local.kube-prometheus["disable_webhooks"]
  render_subchart_notes = local.kube-prometheus["render_subchart_notes"]
  replace               = local.kube-prometheus["replace"]
  reset_values          = local.kube-prometheus["reset_values"]
  reuse_values          = local.kube-prometheus["reuse_values"]
  skip_crds             = local.kube-prometheus["skip_crds"]
  verify                = local.kube-prometheus["verify"]
  values = [
    local.values_kube-prometheus,
    local.kube-prometheus["extra_values"]
  ]

  depends_on = [
    kubernetes_namespace.prometheus,
  ]
}

resource "kubernetes_secret" "alertmanager_config" {
  count = local.kube-prometheus["enabled"] && length(local.kube-prometheus["alertmanager_config"]) > 0 ? 1 : 0
  metadata {
    name      = "alertmanager-${local.kube-prometheus["name"]}-kube-prometheus-alertmanager"
    namespace = local.kube-prometheus["namespace"]
  }
  data = {
    "alertmanager.yaml" = local.kube-prometheus["alertmanager_config"]
  }
}
