locals {
  loki = merge(
    local.helm_defaults,
    {
      enabled                = false
      name                   = "loki"
      namespace              = "loki"
      s3_endpoint            = ""
      s3_region              = ""
      s3_bucket              = ""
      s3_access_key_id       = ""
      s3_secret_access_key   = ""
      default_network_policy = true
      service_monitor        = local.kube-prometheus["enabled"]
      pvc_size               = "5Gi"
      storage_class          = "" # dynamic provisioning
    },
    var.loki
  )

  values_loki = <<VALUES
fullnameOverride: loki

loki:
  auth_enabled: false
  server:
    log_level: info
  limits_config:
    enforce_metric_name: false
    reject_old_samples: true
    reject_old_samples_max_age: 168h
    max_cache_freshness_per_query: 10m
    split_queries_by_interval: 15m
    max_entries_limit_per_query: 50000
  commonConfig:
    replication_factor: 3
  storage:
    type: s3
    bucketNames: 
      chunks: ${local.loki["s3_bucket"]}
      ruler: ${local.loki["s3_bucket"]}
      admin: ${local.loki["s3_bucket"]}
    s3:
      endpoint: ${local.loki["s3_endpoint"]}
      region: ${local.loki["s3_region"]}
      secretAccessKey: $${S3_SECRET_ACCESS_KEY}
      accessKeyId: $${S3_ACCESS_KEY_ID}
      s3ForcePathStyle: true
      insecure: false
      http_config: {}
  schemaConfig:
    configs:
      - from: 2022-01-11
        store: boltdb-shipper
        object_store: s3
        schema: v11
        index:
          prefix: loki_index_
          period: 24h
  analytics:
    reporting_enabled: false

monitoring:
  serviceMonitor:
    enabled: ${local.loki["service_monitor"]}
  selfMonitoring:
    enabled: false
    grafanaAgent:
      installOperator: false
  lokiCanary:
    enabled: false
test:
  enabled: false

write:
  replicas: 2
  resources: {}
  extraArgs:
    - -config.expand-env=true
  extraEnvFrom:
    - secretRef:
        name: loki-s3-credentials
  persistence:
    size: ${local.loki["pvc_size"]}
    storageClass: ${local.loki["storage_class"]}

read:
  replicas: 2
  resources: {}
  extraArgs:
    - -config.expand-env=true
  extraEnvFrom:
    - secretRef:
        name: loki-s3-credentials
  persistence:
    size: ${local.loki["pvc_size"]}
    storageClass: ${local.loki["storage_class"]}

gateway:
  enabled: true
  replicas: 1
  verboseLogging: true
  resources: {}
  ingress:
    enabled: false
  basicAuth:
    enabled: false

networkPolicy:
  enabled: false
VALUES
}


resource "kubernetes_secret" "loki_s3_credentials" {
  count = local.loki["enabled"] ? 1 : 0
  metadata {
    name      = "loki-s3-credentials"
    namespace = local.loki["namespace"]
  }
  data = {
    S3_ACCESS_KEY_ID     = local.loki["s3_access_key_id"]
    S3_SECRET_ACCESS_KEY = local.loki["s3_secret_access_key"]
  }

  depends_on = [
    kubernetes_namespace.loki
  ]
}


resource "kubernetes_namespace" "loki" {
  count = local.loki["enabled"] ? 1 : 0
  metadata {
    name = local.loki["namespace"]
    labels = {
      name = local.loki["namespace"]
    }
  }
}


resource "helm_release" "loki" {
  count                 = local.loki["enabled"] ? 1 : 0
  namespace             = local.loki["namespace"]
  name                  = local.loki["name"]
  repository            = "https://grafana.github.io/helm-charts"
  chart                 = "loki"
  version               = "5.10.0"
  timeout               = local.loki["timeout"]
  force_update          = local.loki["force_update"]
  recreate_pods         = local.loki["recreate_pods"]
  wait                  = local.loki["wait"]
  atomic                = local.loki["atomic"]
  cleanup_on_fail       = local.loki["cleanup_on_fail"]
  dependency_update     = local.loki["dependency_update"]
  disable_crd_hooks     = local.loki["disable_crd_hooks"]
  disable_webhooks      = local.loki["disable_webhooks"]
  render_subchart_notes = local.loki["render_subchart_notes"]
  replace               = local.loki["replace"]
  reset_values          = local.loki["reset_values"]
  reuse_values          = local.loki["reuse_values"]
  skip_crds             = local.loki["skip_crds"]
  verify                = local.loki["verify"]
  values = [
    local.values_loki,
    local.loki["extra_values"]
  ]

  depends_on = [
    kubernetes_namespace.loki,
    helm_release.kube-prometheus
  ]
}


resource "kubernetes_network_policy" "loki_default_deny" {
  count = local.loki["enabled"] && local.loki["default_network_policy"] ? 1 : 0
  metadata {
    name      = "${local.loki["name"]}-default-deny"
    namespace = local.loki["namespace"]
  }
  spec {
    pod_selector {
      match_labels = {
        app = "loki"
      }
    }
    policy_types = ["Ingress"]
  }

  depends_on = [
    kubernetes_namespace.loki
  ]
}


resource "kubernetes_network_policy" "loki_allow_namespace" {
  count = local.loki["enabled"] && local.loki["default_network_policy"] ? 1 : 0
  metadata {
    name      = "${local.loki["name"]}-allow-namespace"
    namespace = local.loki["namespace"]
  }
  spec {
    pod_selector {
      match_labels = {
        app = "loki"
      }
    }
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = local.loki["namespace"]
          }
        }
      }
    }
    policy_types = ["Ingress"]
  }

  depends_on = [
    kubernetes_namespace.loki
  ]
}


resource "kubernetes_network_policy" "loki_allow_prometheus_namespace" {
  count = local.loki["enabled"] && local.loki["default_network_policy"] && local.kube-prometheus["enabled"] ? 1 : 0
  metadata {
    name      = "${local.loki["name"]}-allow-prometheus-namespace"
    namespace = local.loki["namespace"]
  }
  spec {
    pod_selector {
      match_labels = {
        app = "loki"
      }
    }
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = local.kube-prometheus["namespace"]
          }
        }
      }
    }
    policy_types = ["Ingress"]
  }

  depends_on = [
    kubernetes_namespace.loki
  ]
}


resource "kubernetes_network_policy" "loki_allow_grafana" {
  count = local.loki["enabled"] && local.loki["default_network_policy"] && local.grafana["enabled"] ? 1 : 0
  metadata {
    name      = "${local.loki["name"]}-allow-grafana"
    namespace = local.loki["namespace"]
  }
  spec {
    pod_selector {
      match_labels = {
        app = "loki"
      }
    }
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = local.grafana["namespace"]
          }
        }
        pod_selector {
          match_labels = {
            "app.kubernetes.io/name" = "grafana"
          }
        }
      }
    }
    policy_types = ["Ingress"]
  }

  depends_on = [
    kubernetes_namespace.loki
  ]
}
