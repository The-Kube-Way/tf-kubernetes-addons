locals {
  velero = merge(
    local.helm_defaults,
    {
      enabled       = false
      name          = local.helm_dependencies[index(local.helm_dependencies.*.name, "velero")].name
      chart         = local.helm_dependencies[index(local.helm_dependencies.*.name, "velero")].name
      repository    = local.helm_dependencies[index(local.helm_dependencies.*.name, "velero")].repository
      chart_version = local.helm_dependencies[index(local.helm_dependencies.*.name, "velero")].version
      namespace             = "velero"
      velero_priority_class = "high-priority"
      velero_cpu_limit      = "1000m"
      velero_memory_limit   = "512Mi"
      credentials           = ""
      deploy_restic         = true
      restic_password       = "static-passw0rd"  # default velero password
      restic_privileged     = false
      restic_priority_class = "high-priority"
      restic_cpu_limit      = "1000m"
      restic_memory_limit   = "1Gi"
      
    },
    var.velero
  )

  values_velero = <<VALUES
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: ${local.velero["velero_cpu_limit"]}
    memory: ${local.velero["velero_memory_limit"]}

initContainers:
  - name: velero-plugin-for-aws
    image: velero/velero-plugin-for-aws:v1.4.1
    imagePullPolicy: IfNotPresent
    volumeMounts:
      - mountPath: /target
        name: plugins

priorityClassName: ${local.velero["velero_priority_class"]}

metrics:
  enabled: true
  scrapeInterval: 60s
  serviceMonitor:
    enabled: true

upgradeCRDs: true

configuration:
  provider: aws

credentials:
  existingSecret: velero-credentials

backupsEnabled: false  # Do not create a default backup location
snapshotsEnabled: true

deployRestic: ${local.velero["deploy_restic"]}
restic:
  podVolumePath: /var/lib/kubelet/pods
  privileged: ${local.velero["restic_privileged"]}
  priorityClassName: ${local.velero["restic_priority_class"]}
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: ${local.velero["velero_cpu_limit"]}
      memory: ${local.velero["velero_memory_limit"]}
VALUES
}


resource "kubernetes_namespace" "velero" {
  count = local.velero["enabled"] ? 1 : 0
  metadata {
    name = local.velero["namespace"]
    labels = {
      name = local.velero["namespace"]
    }
  }
}


resource "kubernetes_secret" "velero_credentials" {
  count = local.velero["enabled"] ? 1 : 0
  metadata {
    name = "velero-credentials"
    namespace = local.velero["namespace"]
  }
  data = {
    cloud = local.velero["credentials"]
  }
}


resource "kubernetes_secret" "restic_password" {
  count = local.velero["enabled"] && local.velero["deploy_restic"] ? 1 : 0
  metadata {
    name = "velero-restic-credentials"
    namespace = local.velero["namespace"]
  }
  data = {
    repository-password = local.velero["restic_password"]
  }
}


resource "helm_release" "velero" {
  count                 = local.velero["enabled"] ? 1 : 0
  namespace             = local.velero["namespace"]
  repository            = local.velero["repository"]
  name                  = local.velero["name"]
  chart                 = local.velero["chart"]
  version               = local.velero["chart_version"]
  timeout               = local.velero["timeout"]
  force_update          = local.velero["force_update"]
  recreate_pods         = local.velero["recreate_pods"]
  wait                  = local.velero["wait"]
  atomic                = local.velero["atomic"]
  cleanup_on_fail       = local.velero["cleanup_on_fail"]
  dependency_update     = local.velero["dependency_update"]
  disable_crd_hooks     = local.velero["disable_crd_hooks"]
  disable_webhooks      = local.velero["disable_webhooks"]
  render_subchart_notes = local.velero["render_subchart_notes"]
  replace               = local.velero["replace"]
  reset_values          = local.velero["reset_values"]
  reuse_values          = local.velero["reuse_values"]
  skip_crds             = local.velero["skip_crds"]
  verify                = local.velero["verify"]
  values = [
    local.values_velero,
    local.velero["extra_values"]
  ]

  depends_on = [
    kubernetes_namespace.velero,
    kubernetes_secret.velero_credentials,
    kubernetes_secret.restic_password,
    helm_release.kube-prometheus
  ]
}
