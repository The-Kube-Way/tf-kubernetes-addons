locals {
  loki = merge(
    local.helm_defaults,
    {
      enabled                = false
      name                   = local.helm_dependencies[index(local.helm_dependencies.*.name, "loki")].name
      chart                  = local.helm_dependencies[index(local.helm_dependencies.*.name, "loki")].name
      repository             = local.helm_dependencies[index(local.helm_dependencies.*.name, "loki")].repository
      chart_version          = local.helm_dependencies[index(local.helm_dependencies.*.name, "loki")].version
      namespace              = "loki"
      s3_enabled             = true
      s3_endpoint            = ""
      s3_region              = ""
      s3_bucket              = ""
      s3_access_key_id       = ""
      s3_secret_access_key   = ""
      cpu_limit              = "200m"
      memory_limit           = "256Mi"
      persistence            = false
      default_network_policy = true
    },
    var.loki
  )

  values_loki = <<VALUES
config:
  auth_enabled: false
  server:
    log_level: info
  limits_config:
    max_entries_limit_per_query: 50000
  schema_config:
    configs:
      - from: 2020-10-24
        store: boltdb-shipper
        object_store: %{if local.loki["s3_enabled"]}s3%{else}filesystem%{endif}
        schema: v11
        index:
          prefix: loki_index_
          period: 24h
  storage_config:
    %{if local.loki["s3_enabled"]}
    aws:
      bucketnames: ${local.loki["s3_bucket"]}
      endpoint: ${local.loki["s3_endpoint"]}
      region: ${local.loki["s3_region"]}
      access_key_id: ${local.loki["s3_access_key_id"]}
      secret_access_key: ${local.loki["s3_secret_access_key"]}
    %{endif}
    boltdb_shipper:
      shared_store: %{if local.loki["s3_enabled"]}s3%{else}filesystem%{endif}
  compactor:
    shared_store: %{if local.loki["s3_enabled"]}s3%{else}filesystem%{endif}
  analytics:
    reporting_enabled: false

persistence:
  enabled: ${local.loki["persistence"]}

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: ${local.loki["cpu_limit"]}
    memory: ${local.loki["memory_limit"]}

serviceMonitor:
  enabled: ${local.kube-prometheus["enabled"]}
  interval: "60s"
VALUES
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
  repository            = local.loki["repository"]
  name                  = local.loki["name"]
  chart                 = local.loki["chart"]
  version               = local.loki["chart_version"]
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
    kubernetes_namespace.loki
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
