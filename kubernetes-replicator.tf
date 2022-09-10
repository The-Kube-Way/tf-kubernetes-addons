locals {
  kubernetes-replicator = merge(
    local.helm_defaults,
    {
      enabled             = false
      name                = local.helm_dependencies[index(local.helm_dependencies.*.name, "kubernetes-replicator")].name
      chart               = local.helm_dependencies[index(local.helm_dependencies.*.name, "kubernetes-replicator")].name
      repository          = local.helm_dependencies[index(local.helm_dependencies.*.name, "kubernetes-replicator")].repository
      chart_version       = local.helm_dependencies[index(local.helm_dependencies.*.name, "kubernetes-replicator")].version
      namespace           = "default"
      kubernetes_api_cidr = "" # Get with $ kubectl get endpoints kubernetes, e.g., 10.3.0.1/32. "" to disable.
      kubernetes_api_port = 443
    },
    var.kubernetes-replicator
  )

  values_kubernetes-replicator = <<VALUES
fullnameOverride: kubernetes-replicator
args:
  - -log-level=info

securityContext:
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000

resources:
  requests:
    cpu: 10m
    memory: 32Mi
  limits:
    cpu: 50m
    memory: 64Mi
VALUES
}

# Prevent any network connection except to Kubernetes API to avoid (too) easy information extraction
# by a malicious image
# TODO: waiting for https://github.com/cilium/cilium/issues/20550

# resource "kubernetes_network_policy" "kubernetes_replicator_default_deny" {
#   count = local.kubernetes-replicator["enabled"] && length(local.kubernetes-replicator["kubernetes_api_cidr"]) > 0 ? 1 : 0
#   metadata {
#     name      = "kubernetes-replicator-deny-all-network-traffic"
#     namespace = local.kubernetes-replicator["namespace"]
#   }
#   spec {
#     pod_selector {
#       match_labels = {
#         "app.kubernetes.io/name" = "kubernetes-replicator"
#       }
#     }
#     policy_types = ["Ingress", "Egress"]
#     egress {
#       ports {
#         port     = local.kubernetes-replicator["kubernetes_api_port"]
#         protocol = "TCP"
#       }
#       to {
#         ip_block {
#           cidr = local.kubernetes-replicator["kubernetes_api_cidr"]
#         }
#       }
#     }
#   }
# }

resource "helm_release" "kubernetes_replicator" {
  count                 = local.kubernetes-replicator["enabled"] ? 1 : 0
  namespace             = local.kubernetes-replicator["namespace"]
  repository            = local.kubernetes-replicator["repository"]
  name                  = local.kubernetes-replicator["name"]
  chart                 = local.kubernetes-replicator["chart"]
  version               = local.kubernetes-replicator["chart_version"]
  timeout               = local.kubernetes-replicator["timeout"]
  force_update          = local.kubernetes-replicator["force_update"]
  recreate_pods         = local.kubernetes-replicator["recreate_pods"]
  wait                  = local.kubernetes-replicator["wait"]
  atomic                = local.kubernetes-replicator["atomic"]
  cleanup_on_fail       = local.kubernetes-replicator["cleanup_on_fail"]
  dependency_update     = local.kubernetes-replicator["dependency_update"]
  disable_crd_hooks     = local.kubernetes-replicator["disable_crd_hooks"]
  disable_webhooks      = local.kubernetes-replicator["disable_webhooks"]
  render_subchart_notes = local.kubernetes-replicator["render_subchart_notes"]
  replace               = local.kubernetes-replicator["replace"]
  reset_values          = local.kubernetes-replicator["reset_values"]
  reuse_values          = local.kubernetes-replicator["reuse_values"]
  skip_crds             = local.kubernetes-replicator["skip_crds"]
  verify                = local.kubernetes-replicator["verify"]
  values = [
    local.values_kubernetes-replicator,
    local.kubernetes-replicator["extra_values"]
  ]
}
