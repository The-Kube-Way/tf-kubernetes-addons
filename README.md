# Common Kubernetes helm charts using Terraform

[![Project Status: Abandoned – Initial development has started, but there has not yet been a stable, usable release; the project has been abandoned and the author(s) do not intend on continuing development.](https://www.repostatus.org/badges/latest/abandoned.svg)](https://www.repostatus.org/#abandoned)

⚠️ **Open-source version of this project is not maintained anymore, sorry! (but feel free to fork!)**

This project aims to provide widely used Helm Charts as Terraform modules to reduce the cost of maintaining multiple homogeneous clusters.


## Features

This repository is composed on independent Terraform modules.

- Backup
  - Velero
- Base
  - Kubernetes replicator
  - Priority classes
- Ingress
  - Ingress-nginx
  - Cert-manager
- Monitoring
  - Prometheus (with exporters)
  - Loki
  - Promtail
  - Grafana
  - Kubernetes event exporter
- Network
  - Tigera Operator
- Security
  - Falco
- Scaling
  - Cluster autoscaler

## Usage

Users are **highly encouraged** to pin a specific commit hash

```terraform
module "k8s_base" {
  source = "github.com/The-Kube-Way/tf-kubernetes-addons/base?ref=$COMMIT_HASH"
}
```

When updating the hash, use `terraform plan` to verify that the changes that will be applied are what you expect.

# Customize Helm Charts

Each Helm chart can be customized using variables.
Check *.tf files for available parameters.
Furthermore, chart values can be overwritten using `extra_values` key.

Example:
```terraform
module "k8s_base" {
  source = "github.com/The-Kube-Way/tf-kubernetes-addons/base"

  priority_classes = {
    enabled = true
  }

  kubernetes-replicator = {
    enabled = true
  }
}

module "k8s_backup" {
  source = "github.com/The-Kube-Way/tf-kubernetes-addons/backup"

  velero = {
    enabled = true
    restic_password = "xxx"
    credentials = <<VALUES
[default]
aws_access_key_id = ${var.xxx}
aws_secret_access_key = ${var.xxx}
VALUES
    default_backup_storage_location = {
        enabled             = true
        read_only           = false
        s3_url              = "xxx"
        s3_region           = "xxx"
        s3_force_path_style = true
        s3_bucket           = "xxx"
      }
    restic_memory_limit = "2Gi"
  }
}

module "k8s_ingress" {
  source = "github.com/The-Kube-Way/tf-kubernetes-addons/ingress"
  ingress-nginx= {
    enabled = true
  }
  cert-manager = {
    enabled = true
  }
}

module "k8s_monitoring" {
  source = "github.com/The-Kube-Way/tf-kubernetes-addons/monitoring"
  kube-prometheus = {
    enabled = true
    persistence = true
    fix_volume_permissions = false
    alertmanager_config = <<VALUES
xxx
VALUES
  }
  grafana = {
    enabled = true
  }

  loki = {
    enabled              = true
    s3_endpoint          = "xxx"
    s3_region            = "xxx"
    s3_bucket            = "xxx"
    s3_access_key_id     = "xxx"
    s3_secret_access_key = "xxx"
    extra_values = <<VALUES
global:
  dnsService: coredns
VALUES

  }
  promtail = {
    enabled = true
  }
  kubernetes_event_exporter = {
    enabled = true
  }
}

module "k8s_security" {
  source = "github.com/The-Kube-Way/tf-kubernetes-addons/security"
  falco = {
    enabled = true
  }
}
```

# Chart updates

Chart versions are automatically updated using [Renovate](https://renovatebot.com/).
Major versions are merged manually.
