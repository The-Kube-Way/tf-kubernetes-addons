# Common Kubernetes helm charts using Terraform

[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![tf-kubernetes-addons](https://github.com/The-Kube-Way/tf-kubernetes-addons/actions/workflows/terraform.yaml/badge.svg?branch=master)](https://github.com/The-Kube-Way/tf-kubernetes-addons/actions/workflows/terraform.yaml)

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
locals {
  k8s_addons_version = "master"  # Pin a specific commit hash!
}

module "k8s_base" {
  source = "github.com/The-Kube-Way/tf-kubernetes-addons/base?ref=${local.k8s_addons_version}"

  priority_classes = {
    enabled = true
  }

  kubernetes-replicator = {
    enabled = true
  }
}

module "k8s_backup" {
  source = "github.com/The-Kube-Way/tf-kubernetes-addons/backup?ref=${local.k8s_addons_version}"

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
  source = "github.com/The-Kube-Way/tf-kubernetes-addons/ingress?ref=${local.k8s_addons_version}"
  ingress-nginx= {
    enabled = true
  }
  cert-manager = {
    enabled = true
  }
}

module "k8s_monitoring" {
  source = "github.com/The-Kube-Way/tf-kubernetes-addons/monitoring?ref=${local.k8s_addons_version}"
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
  source = "github.com/The-Kube-Way/tf-kubernetes-addons/security?ref=${local.k8s_addons_version}"
  falco = {
    enabled = true
  }
}
```

# Chart updates

Chart versions are automatically updated using [Renovate](https://renovatebot.com/).
Major versions are merged manually.
