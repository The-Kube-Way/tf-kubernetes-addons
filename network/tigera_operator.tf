locals {
  tigera-operator = merge(
    local.helm_defaults,
    {
      name                   = "tigera-operator"
      namespace              = "tigera-operator"
      create_ns              = true
      enabled                = false
      default_network_policy = true
    },
    var.tigera-operator
  )

  values_tigera-operator = <<-VALUES
    installation:
      kubernetesProvider: EKS
    VALUES
}

resource "kubernetes_namespace" "tigera_operator" {
  count = local.tigera-operator["enabled"] && local.tigera-operator["create_ns"] ? 1 : 0
  metadata {
    name = local.tigera-operator["namespace"]
    labels = {
      name = local.tigera-operator["namespace"]
    }
  }
}

resource "helm_release" "tigera_operator" {
  count                 = local.tigera-operator["enabled"] ? 1 : 0
  namespace             = local.tigera-operator["namespace"]
  name                  = local.tigera-operator["name"]
  repository            = "https://docs.projectcalico.org/charts"
  chart                 = "tigera-operator"
  version               = "v3.25.1"
  timeout               = local.tigera-operator["timeout"]
  force_update          = local.tigera-operator["force_update"]
  recreate_pods         = local.tigera-operator["recreate_pods"]
  wait                  = local.tigera-operator["wait"]
  atomic                = local.tigera-operator["atomic"]
  cleanup_on_fail       = local.tigera-operator["cleanup_on_fail"]
  dependency_update     = local.tigera-operator["dependency_update"]
  disable_crd_hooks     = local.tigera-operator["disable_crd_hooks"]
  disable_webhooks      = local.tigera-operator["disable_webhooks"]
  render_subchart_notes = local.tigera-operator["render_subchart_notes"]
  replace               = local.tigera-operator["replace"]
  reset_values          = local.tigera-operator["reset_values"]
  reuse_values          = local.tigera-operator["reuse_values"]
  skip_crds             = local.tigera-operator["skip_crds"]
  verify                = local.tigera-operator["verify"]
  values = [
    local.values_tigera-operator,
    local.tigera-operator["extra_values"]
  ]

  depends_on = [
    kubernetes_namespace.tigera_operator
  ]
}

resource "kubernetes_network_policy" "tigera_operator_default_deny" {
  count = local.tigera-operator["create_ns"] && local.tigera-operator["enabled"] && local.tigera-operator["default_network_policy"] ? 1 : 0
  metadata {
    name      = "tigera-operator-default-deny"
    namespace = local.tigera-operator["namespace"]
  }
  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "tigera_operator_allow_namespace" {
  count = local.tigera-operator["create_ns"] && local.tigera-operator["enabled"] && local.tigera-operator["default_network_policy"] ? 1 : 0
  metadata {
    name      = "tigera-operator-allow-namespace"
    namespace = local.tigera-operator["namespace"]
  }
  spec {
    pod_selector {}
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = local.tigera-operator["namespace"]
          }
        }
      }
    }
    policy_types = ["Ingress"]
  }
}
