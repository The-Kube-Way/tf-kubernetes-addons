locals {
  cert-manager = merge(
    local.helm_defaults,
    {
      enabled   = false
      name      = "cert-manager"
      namespace = "cert-manager"
    },
    var.cert-manager
  )

  values_cert-manager = <<VALUES
installCRDs: true
VALUES
}


resource "kubernetes_namespace" "cert_manager" {
  count = local.cert-manager["enabled"] ? 1 : 0
  metadata {
    name = local.cert-manager["namespace"]
    labels = {
      name = local.cert-manager["namespace"]
    }
  }
}


resource "helm_release" "cert_manager" {
  count                 = local.cert-manager["enabled"] ? 1 : 0
  namespace             = local.cert-manager["namespace"]
  name                  = local.cert-manager["name"]
  repository            = "https://charts.jetstack.io"
  chart                 = "cert-manager"
  version               = "v1.12.3"
  timeout               = local.cert-manager["timeout"]
  force_update          = local.cert-manager["force_update"]
  recreate_pods         = local.cert-manager["recreate_pods"]
  wait                  = local.cert-manager["wait"]
  atomic                = local.cert-manager["atomic"]
  cleanup_on_fail       = local.cert-manager["cleanup_on_fail"]
  dependency_update     = local.cert-manager["dependency_update"]
  disable_crd_hooks     = local.cert-manager["disable_crd_hooks"]
  disable_webhooks      = local.cert-manager["disable_webhooks"]
  render_subchart_notes = local.cert-manager["render_subchart_notes"]
  replace               = local.cert-manager["replace"]
  reset_values          = local.cert-manager["reset_values"]
  reuse_values          = local.cert-manager["reuse_values"]
  skip_crds             = local.cert-manager["skip_crds"]
  verify                = local.cert-manager["verify"]
  values = [
    local.values_cert-manager,
    local.cert-manager["extra_values"]
  ]

  depends_on = [
    kubernetes_namespace.cert_manager
  ]
}
